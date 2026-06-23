# frozen_string_literal: true

module SupplyChain
  # Evaluates a single CveMonitor server-side: walks the monitor's scope,
  # broadcasts CVE alerts over ActionCable, and records the run timestamp.
  #
  # Extracted from the worker CveMonitoringJob so the standalone Sidekiq worker
  # can stay HTTP-only (no ActiveRecord). The worker job now POSTs to
  # /api/v1/internal/supply_chain/cve_monitors/:id/run, which invokes this.
  class CveMonitorRunner
    # @param monitor [SupplyChain::CveMonitor]
    def initialize(monitor)
      @monitor = monitor
      @account = monitor.account
      @alerts_sent = 0
    end

    # @return [Hash] { monitor_id:, scope_type:, alerts_sent: }
    def run!
      case @monitor.scope_type
      when "account_wide" then check_account_wide
      when "repository"   then check_repository_scope
      when "image"        then check_image_scope
      end

      @monitor.update!(last_run_at: Time.current)

      { monitor_id: @monitor.id, scope_type: @monitor.scope_type, alerts_sent: @alerts_sent }
    end

    private

    attr_reader :monitor, :account

    def broadcast(alert)
      return if alert.nil?

      SupplyChainChannel.broadcast_cve_alert(account, alert)
      @alerts_sent += 1
    end

    def check_account_wide
      account.supply_chain_sboms.each do |sbom|
        critical_vulns = sbom.vulnerabilities.where(severity: "critical")
        high_vulns = sbom.vulnerabilities.where(severity: "high")

        if critical_vulns.any? && monitor.min_severity.in?(%w[critical high medium low])
          broadcast(create_alert(sbom, critical_vulns.first, "critical"))
        end

        if high_vulns.any? && monitor.min_severity.in?(%w[high medium low])
          broadcast(create_alert(sbom, high_vulns.first, "high"))
        end
      end
    end

    def check_repository_scope
      return if monitor.scope_id.blank?

      sboms = account.supply_chain_sboms.where(git_repository_id: monitor.scope_id)
      check_sboms_for_monitor(sboms)
    end

    def check_image_scope
      return if monitor.scope_id.blank?

      image = account.supply_chain_container_images.find_by(id: monitor.scope_id)
      return unless image

      latest_scan = image.vulnerability_scans.order(created_at: :desc).first
      return unless latest_scan

      if latest_scan.critical_count.to_i.positive? && monitor.min_severity.in?(%w[critical high medium low])
        broadcast(
          type: "container_vulnerability",
          severity: "critical",
          image_id: image.id,
          image_reference: image.full_reference,
          vulnerability_count: latest_scan.critical_count
        )
      end
    end

    def check_sboms_for_monitor(sboms)
      sboms.each do |sbom|
        vulns = sbom.vulnerabilities.where(severity: severities_for_min(monitor.min_severity))

        vulns.where("created_at > ?", monitor.last_run_at || 1.day.ago).each do |vuln|
          broadcast(create_alert(sbom, vuln, vuln.severity))
        end
      end
    end

    def create_alert(sbom, vuln, severity)
      {
        monitor_id: monitor.id,
        vulnerability_id: vuln.vulnerability_id,
        severity: severity,
        cvss_score: vuln.cvss_score,
        sbom_id: sbom.id,
        sbom_name: sbom.name,
        component: vuln.component&.name,
        version: vuln.component&.version,
        fixed_version: vuln.fixed_version
      }
    end

    def severities_for_min(min_severity)
      case min_severity
      when "critical" then %w[critical]
      when "high" then %w[critical high]
      when "medium" then %w[critical high medium]
      else %w[critical high medium low]
      end
    end
  end
end
