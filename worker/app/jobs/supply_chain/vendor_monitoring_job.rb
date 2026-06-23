# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates vendor monitoring to the server, which iterates the
  # account's active vendors, surfaces/creates monitoring events and broadcasts
  # them (all ActiveRecord + ActionCable). The worker is API-only and holds no models.
  #
  # +account_id+ scopes the sweep to a single account; when nil the server sweeps
  # every account that has an active vendor.
  class VendorMonitoringJob < ApplicationJob
    queue_as :supply_chain_monitoring

    def execute(account_id = nil)
      response = api_client.post(
        "/api/v1/internal/supply_chain/vendors/monitor",
        { account_id: account_id }
      )
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
