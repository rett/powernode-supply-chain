# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoint for verifying a build's
        # reproducibility. The standalone worker's
        # SupplyChain::ReproducibilityVerificationJob POSTs here so the
        # ActiveRecord + ActionCable work happens server-side. Operates on an
        # explicit provenance id (trusted internal caller — not scoped to
        # current_account).
        class BuildProvenanceController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/build_provenance/:id/verify
          def verify
            provenance = ::SupplyChain::BuildProvenance.find(params[:id])
            user = ::User.find_by(id: params[:user_id])
            result = ::SupplyChain::ReproducibilityVerifier.new(provenance, user).verify!

            render_success(result)
          rescue ActiveRecord::RecordNotFound
            render_error("Build provenance not found", status: :not_found)
          end
        end
      end
    end
  end
end
