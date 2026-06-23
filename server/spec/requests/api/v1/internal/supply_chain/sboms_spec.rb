# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::Sboms", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  before do
    allow(SupplyChainChannel).to receive(:broadcast_vulnerability_correlation_completed)
    allow(SupplyChainChannel).to receive(:broadcast_critical_vulnerability_found)
    allow(SupplyChainChannel).to receive(:broadcast_sbom_created)
  end

  describe "POST /api/v1/internal/supply_chain/sboms/:id/vulnerability_scan" do
    let(:sbom) { create(:supply_chain_sbom, account: account, status: "completed") }
    let!(:critical) { create(:supply_chain_sbom_vulnerability, :critical, sbom: sbom, account: account) }

    it "correlates vulnerabilities and returns a summary" do
      post "/api/v1/internal/supply_chain/sboms/#{sbom.id}/vulnerability_scan", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["sbom_id"]).to eq(sbom.id)
      expect(data).to have_key("vulnerability_count")
    end

    it "broadcasts correlation completion and critical alerts" do
      post "/api/v1/internal/supply_chain/sboms/#{sbom.id}/vulnerability_scan", headers: headers, as: :json

      expect(SupplyChainChannel)
        .to have_received(:broadcast_vulnerability_correlation_completed)
        .with(an_instance_of(::SupplyChain::Sbom), kind_of(Integer))
      expect(SupplyChainChannel)
        .to have_received(:broadcast_critical_vulnerability_found).at_least(:once)
    end

    it "returns 404 for an unknown sbom" do
      post "/api/v1/internal/supply_chain/sboms/#{SecureRandom.uuid}/vulnerability_scan", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/sboms/#{sbom.id}/vulnerability_scan", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/internal/supply_chain/sboms/generate" do
    let(:sbom) { create(:supply_chain_sbom, account: account, status: "completed") }
    let(:generation_service) { instance_double(::SupplyChain::SbomGenerationService, generate: sbom) }
    let(:params) do
      {
        account_id: account.id,
        options: { source_path: "/tmp/repo", ecosystems: [ "npm" ], format: "cyclonedx_1_5" }
      }
    end

    before do
      allow(::SupplyChain::SbomGenerationService).to receive(:new).and_return(generation_service)
      allow(WorkerJobService).to receive(:enqueue_job)
    end

    it "generates an SBOM and returns its id" do
      post "/api/v1/internal/supply_chain/sboms/generate", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["sbom_id"]).to eq(sbom.id)
    end

    it "broadcasts creation and enqueues a follow-up vulnerability scan" do
      post "/api/v1/internal/supply_chain/sboms/generate", params: params, headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_sbom_created).with(sbom)
      expect(WorkerJobService).to have_received(:enqueue_job).with(
        "SupplyChain::VulnerabilityScanJob", args: [ sbom.id ], queue: "supply_chain_default"
      )
    end

    it "skips the follow-up scan when scan_vulnerabilities is false" do
      post "/api/v1/internal/supply_chain/sboms/generate",
           params: params.deep_merge(options: { scan_vulnerabilities: false }),
           headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(WorkerJobService).not_to have_received(:enqueue_job)
    end

    it "returns 404 for an unknown account" do
      post "/api/v1/internal/supply_chain/sboms/generate",
           params: { account_id: SecureRandom.uuid }, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/sboms/generate", params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
