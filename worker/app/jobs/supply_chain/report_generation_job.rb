# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates report generation to the server, which aggregates
  # across the supply-chain schema, persists the generated content onto the
  # Report record, and broadcasts the generation lifecycle (all ActiveRecord +
  # ActionCable). The worker is API-only and holds no models.
  #
  # +report_id+ is a SupplyChain::Report id (the dispatching ReportsController
  # passes @report.id).
  class ReportGenerationJob < ApplicationJob
    queue_as :supply_chain_reports

    def execute(report_id)
      response = api_client.post("/api/v1/internal/supply_chain/reports/#{report_id}/generate", {})
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
