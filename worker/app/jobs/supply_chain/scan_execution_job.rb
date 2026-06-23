# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates a scan execution to the server, which dispatches by
  # the scan template's category, runs the appropriate scanner service, persists
  # results, optionally auto-remediates, and broadcasts lifecycle events — all
  # ActiveRecord + ActionCable. The worker is API-only and holds no models.
  #
  # +execution_id+ is a ScanExecution id (the dispatching controller passes
  # @execution.id). The server marks the execution failed and re-raises on a
  # scanner error, so the resulting 5xx lets Sidekiq retry.
  class ScanExecutionJob < ApplicationJob
    queue_as :supply_chain_scans

    def execute(execution_id)
      response = api_client.post(
        "/api/v1/internal/supply_chain/scan_executions/#{execution_id}/run", {}
      )
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
