# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoints for SBOM vulnerability scanning and
        # generation. The standalone worker's SupplyChain::VulnerabilityScanJob and
        # SupplyChain::SbomGenerationJob POST here so all ActiveRecord + ActionCable
        # work happens server-side. Operates on explicit resource ids (trusted
        # internal caller — not scoped to current_account).
        class SbomsController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/sboms/:id/vulnerability_scan
          def vulnerability_scan
            sbom = ::SupplyChain::Sbom.find(params[:id])

            count = ::SupplyChain::VulnerabilityCorrelationService.new(sbom: sbom).correlate!
            ::SupplyChain::RiskCalculationService.new(sbom: sbom).calculate!

            SupplyChainChannel.broadcast_vulnerability_correlation_completed(sbom, count)
            sbom.vulnerabilities.where(severity: "critical").each do |vuln|
              SupplyChainChannel.broadcast_critical_vulnerability_found(vuln)
            end

            render_success(sbom_id: sbom.id, vulnerability_count: count)
          rescue ActiveRecord::RecordNotFound
            render_error("SBOM not found", status: :not_found)
          end

          # POST /api/v1/internal/supply_chain/sboms/generate
          def generate
            account = ::Account.find(params[:account_id])
            repository = account.devops_repositories.find(params[:repository_id]) if params[:repository_id].present?

            options = generation_options
            sbom = ::SupplyChain::SbomGenerationService.new(
              account: account,
              repository: repository,
              options: options
            ).generate(
              source_path: options[:source_path],
              ecosystems: options[:ecosystems],
              format: options[:format] || "cyclonedx_1_5"
            )

            SupplyChainChannel.broadcast_sbom_created(sbom)

            if options[:scan_vulnerabilities] != false
              begin
                WorkerJobService.enqueue_job(
                  "SupplyChain::VulnerabilityScanJob",
                  args: [ sbom.id ],
                  queue: "supply_chain_default"
                )
              rescue WorkerJobService::WorkerServiceError => e
                Rails.logger.warn "[Internal::Sboms] Worker unavailable for vulnerability scan: #{e.message}"
              end
            end

            render_success(sbom_id: sbom.id)
          rescue ActiveRecord::RecordNotFound
            render_error("Account or repository not found", status: :not_found)
          end

          private

          # Normalizes the inbound options payload (trusted internal caller) into a
          # HashWithIndifferentAccess regardless of whether it arrives as
          # ActionController::Parameters, a plain Hash, or nil.
          def generation_options
            raw = params[:options]
            raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
            (raw || {}).with_indifferent_access
          end
        end
      end
    end
  end
end
