# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates SBOM generation to the server, which runs the
  # SbomGenerationService, broadcasts creation, and (unless disabled) enqueues a
  # follow-up vulnerability scan (all ActiveRecord + ActionCable). The worker is
  # API-only and holds no models.
  #
  # +account_id+/+repository_id+ are resolved server-side; +options+ carries
  # source_path/ecosystems/format/scan_vulnerabilities.
  class SbomGenerationJob < ApplicationJob
    queue_as :supply_chain_default

    def execute(account_id, repository_id, options = {})
      response = api_client.post(
        "/api/v1/internal/supply_chain/sboms/generate",
        {
          account_id: account_id,
          repository_id: repository_id,
          options: options
        }
      )
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
