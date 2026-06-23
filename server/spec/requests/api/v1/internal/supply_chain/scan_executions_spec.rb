# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::ScanExecutions", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  let(:template) { create(:supply_chain_scan_template, :security, account: nil) }
  let(:instance) do
    create(:supply_chain_scan_instance, account: account, scan_template: template, configuration: {})
  end
  let(:sbom) { create(:supply_chain_sbom, account: account) }
  let(:execution) do
    create(:supply_chain_scan_execution,
      account: account,
      scan_instance: instance,
      status: "pending",
      input_data: { "target_type" => "SupplyChain::Sbom", "target_id" => sbom.id })
  end

  let(:correlation_service) { instance_double(SupplyChain::VulnerabilityCorrelationService) }

  before do
    allow(SupplyChainChannel).to receive(:broadcast_execution_started)
    allow(SupplyChainChannel).to receive(:broadcast_execution_completed)
    allow(SupplyChainChannel).to receive(:broadcast_execution_failed)
    # Stub the heavy scanner; the runner's orchestration runs for real against the DB.
    allow(SupplyChain::VulnerabilityCorrelationService).to receive(:new).and_return(correlation_service)
    allow(correlation_service).to receive(:correlate!)
      .and_return({ total_vulnerabilities: 3, critical: 1, high: 2 })
  end

  describe "POST /api/v1/internal/supply_chain/scan_executions/:id/run" do
    it "runs the execution and returns a summary" do
      post "/api/v1/internal/supply_chain/scan_executions/#{execution.id}/run", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["execution_id"]).to eq(execution.id)
      expect(data["status"]).to eq("completed")
      expect(data["output_data"]["findings_count"]).to eq(3)
    end

    it "marks the execution completed" do
      post "/api/v1/internal/supply_chain/scan_executions/#{execution.id}/run", headers: headers, as: :json
      expect(execution.reload.status).to eq("completed")
    end

    it "broadcasts execution lifecycle events" do
      post "/api/v1/internal/supply_chain/scan_executions/#{execution.id}/run", headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_execution_started)
      expect(SupplyChainChannel).to have_received(:broadcast_execution_completed)
    end

    it "returns 404 for an unknown execution" do
      post "/api/v1/internal/supply_chain/scan_executions/#{SecureRandom.uuid}/run", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/scan_executions/#{execution.id}/run", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
