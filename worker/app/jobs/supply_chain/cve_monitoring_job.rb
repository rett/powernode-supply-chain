# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates CVE-monitor evaluation to the server, which runs
  # the monitor's scope, broadcasts alerts and records the run (all ActiveRecord
  # + ActionCable). The worker is API-only and holds no models.
  #
  # +monitor_id+ is a CveMonitor id (the dispatching CveMonitorsController passes
  # @monitor.id). When nil, the server sweeps all active monitors.
  class CveMonitoringJob < ApplicationJob
    queue_as :supply_chain_monitoring

    def execute(monitor_id = nil)
      path =
        if monitor_id.present?
          "/api/v1/internal/supply_chain/cve_monitors/#{monitor_id}/run"
        else
          "/api/v1/internal/supply_chain/cve_monitors/run_all"
        end

      response = api_client.post(path, {})
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
