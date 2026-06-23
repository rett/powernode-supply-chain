# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates container-image vulnerability scanning to the
  # server, which runs the scan, evaluates policies, broadcasts progress and
  # persists the VulnerabilityScan (all ActiveRecord + ActionCable). The worker
  # is API-only and holds no models.
  #
  # +container_image_id+ is a ContainerImage id. +options+ (scanner,
  # evaluate_policies, ...) are forwarded to the server in the request body.
  class ContainerScanJob < ApplicationJob
    queue_as :supply_chain_default

    def execute(container_image_id, options = {})
      response = api_client.post(
        "/api/v1/internal/supply_chain/container_images/#{container_image_id}/scan",
        { options: options }
      )
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
