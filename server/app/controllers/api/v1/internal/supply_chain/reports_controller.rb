# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoint for generating supply-chain reports.
        # The standalone worker's SupplyChain::ReportGenerationJob POSTs here so the
        # ActiveRecord + ActionCable work happens server-side. Operates on an explicit
        # report id (trusted internal caller — not scoped to current_account).
        class ReportsController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/reports/:id/generate
          def generate
            report = ::SupplyChain::Report.find(params[:id])
            ::SupplyChain::ReportBuilder.new(report).build!

            # Wrap in a positional hash so `status` is a data field, not the
            # reserved render_success HTTP-status keyword.
            render_success({ report_id: report.id, status: report.reload.status })
          rescue ActiveRecord::RecordNotFound
            render_error("Report not found", status: :not_found)
          end
        end
      end
    end
  end
end
