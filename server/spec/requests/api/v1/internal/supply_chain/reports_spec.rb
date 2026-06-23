# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::Reports", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  before do
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_started)
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_completed)
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_failed)
  end

  describe "POST /api/v1/internal/supply_chain/reports/:id/generate" do
    let(:report) do
      create(:supply_chain_report, account: account, report_type: "compliance", format: "json")
    end

    it "generates the report and returns its id and status" do
      post "/api/v1/internal/supply_chain/reports/#{report.id}/generate", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["report_id"]).to eq(report.id)
      expect(data["status"]).to eq("completed")
    end

    it "broadcasts the generation lifecycle" do
      post "/api/v1/internal/supply_chain/reports/#{report.id}/generate", headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_report_generation_started)
      expect(SupplyChainChannel).to have_received(:broadcast_report_generation_completed)
    end

    it "marks the report completed" do
      expect do
        post "/api/v1/internal/supply_chain/reports/#{report.id}/generate", headers: headers, as: :json
      end.to change { report.reload.status }.to("completed")
    end

    it "returns 404 for an unknown report" do
      post "/api/v1/internal/supply_chain/reports/#{SecureRandom.uuid}/generate", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/reports/#{report.id}/generate", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
