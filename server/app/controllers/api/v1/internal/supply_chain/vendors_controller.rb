# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoint for running vendor monitoring.
        # The standalone worker's SupplyChain::VendorMonitoringJob POSTs here so the
        # ActiveRecord + ActionCable work happens server-side. Operates on an explicit
        # account_id from the body (trusted internal caller — not scoped to
        # current_account); a nil account_id sweeps every account with active vendors.
        class VendorsController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/vendors/monitor
          def monitor
            result = ::SupplyChain::VendorMonitorRunner.new(params[:account_id]).run!

            render_success(result)
          end
        end
      end
    end
  end
end
