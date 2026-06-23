# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoints for running CVE monitors.
        # The standalone worker's SupplyChain::CveMonitoringJob POSTs here so the
        # ActiveRecord + ActionCable work happens server-side. Operates on explicit
        # resource ids (trusted internal caller — not scoped to current_account).
        class CveMonitorsController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/cve_monitors/:id/run
          def run
            monitor = ::SupplyChain::CveMonitor.find(params[:id])
            result = ::SupplyChain::CveMonitorRunner.new(monitor).run!

            render_success(result)
          rescue ActiveRecord::RecordNotFound
            render_error("CVE monitor not found", status: :not_found)
          end

          # POST /api/v1/internal/supply_chain/cve_monitors/run_all
          def run_all
            summaries = []

            ::SupplyChain::CveMonitor.active.find_each do |monitor|
              summaries << ::SupplyChain::CveMonitorRunner.new(monitor).run!
            rescue StandardError => e
              Rails.logger.error "[Internal::CveMonitors] monitor #{monitor.id} failed: #{e.message}"
            end

            render_success(
              monitors_run: summaries.size,
              alerts_sent: summaries.sum { |s| s[:alerts_sent] }
            )
          end
        end
      end
    end
  end
end
