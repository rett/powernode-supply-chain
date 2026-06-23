# frozen_string_literal: true

module Api
  module V1
    module Internal
      module SupplyChain
        # Internal (worker-only, mTLS) endpoints for scanning container images.
        # The standalone worker's SupplyChain::ContainerScanJob POSTs here so the
        # ActiveRecord + ActionCable work happens server-side. Operates on explicit
        # resource ids (trusted internal caller — not scoped to current_account).
        class ContainerImagesController < Api::V1::Internal::InternalBaseController
          # POST /api/v1/internal/supply_chain/container_images/:id/scan
          def scan
            image = ::SupplyChain::ContainerImage.find(params[:id])
            options = scan_options

            SupplyChainChannel.broadcast_scan_started(image)

            scan = ::SupplyChain::ContainerScanService.new(
              account: image.account,
              image: image,
              options: options
            ).scan!

            SupplyChainChannel.broadcast_scan_completed(scan)

            # Evaluate policies by default; the caller opts out with evaluate_policies: false.
            evaluate_policies_for(image) unless options[:evaluate_policies] == false

            render_success(
              scan_id: scan.id,
              container_image_id: image.id,
              vulnerability_counts: {
                critical: scan.critical_count,
                high: scan.high_count,
                medium: scan.medium_count,
                low: scan.low_count,
                total: scan.total_vulnerabilities
              }
            )
          rescue ActiveRecord::RecordNotFound
            render_error("Container image not found", status: :not_found)
          end

          private

          def evaluate_policies_for(image)
            result = ::SupplyChain::ContainerScanService.new(
              account: image.account,
              image: image
            ).evaluate_policies

            SupplyChainChannel.broadcast_policy_evaluation_completed(image.account, result)

            Array(result[:policy_results]).each do |policy_result|
              next if policy_result[:passed] || policy_result[:skipped]

              SupplyChainChannel.broadcast_policy_violation(image.account, {
                policy_id: policy_result[:policy_id],
                policy_name: policy_result[:policy_name],
                violations: policy_result[:violations]
              })
            end
          end

          def scan_options
            raw = params[:options]
            return {} if raw.blank?

            raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
            raw.to_h.with_indifferent_access
          end
        end
      end
    end
  end
end
