# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoint for running a scan execution.
        # The standalone worker's SupplyChain::ScanExecutionJob POSTs here so the
        # scan dispatch + ActiveRecord + ActionCable work happens server-side.
        # Operates on an explicit execution id (trusted internal caller — not
        # scoped to current_account).
        class ScanExecutionsController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/scan_executions/:id/run
          #
          # The runner re-raises on scanner failure (after marking the execution
          # failed + broadcasting); that propagates here as a 500 so the worker's
          # API client surfaces the failure and Sidekiq can retry.
          def run
            execution = ::SupplyChain::ScanExecution.find(params[:id])
            result = ::SupplyChain::ScanExecutionRunner.new(execution).run!

            # NOTE: `status:` is a reserved render_success kwarg (HTTP status);
            # wrap the payload in `data:` so `status`/`output_data` are returned
            # as data fields rather than coerced into the HTTP status line.
            render_success(
              data: {
                execution_id: execution.id,
                status: execution.reload.status,
                output_data: result
              }
            )
          rescue ActiveRecord::RecordNotFound
            render_error("Scan execution not found", status: :not_found)
          end
        end
      end
    end
  end
end
