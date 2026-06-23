# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::ContainerImages", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  before do
    allow(SupplyChainChannel).to receive(:broadcast_scan_started)
    allow(SupplyChainChannel).to receive(:broadcast_scan_completed)
    allow(SupplyChainChannel).to receive(:broadcast_policy_evaluation_completed)
    allow(SupplyChainChannel).to receive(:broadcast_policy_violation)
  end

  describe "POST /api/v1/internal/supply_chain/container_images/:id/scan" do
    let(:image) { create(:supply_chain_container_image, account: account) }
    let(:body) { { options: { scanner: "trivy", evaluate_policies: true } } }

    it "scans the image and returns a summary" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: body, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["scan_id"]).to be_present
      expect(data["container_image_id"]).to eq(image.id)
      expect(data["vulnerability_counts"]).to include("critical", "high", "medium", "low", "total")
    end

    it "broadcasts scan lifecycle events" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: body, headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_scan_started).with(image)
      expect(SupplyChainChannel).to have_received(:broadcast_scan_completed)
    end

    it "evaluates policies when requested" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: body, headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_policy_evaluation_completed)
    end

    it "evaluates policies by default when evaluate_policies is omitted" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: { options: { scanner: "trivy" } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(SupplyChainChannel).to have_received(:broadcast_policy_evaluation_completed)
    end

    it "skips policy evaluation when evaluate_policies is explicitly false" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: { options: { scanner: "trivy", evaluate_policies: false } },
           headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(SupplyChainChannel).not_to have_received(:broadcast_policy_evaluation_completed)
    end

    it "returns 404 for an unknown image" do
      post "/api/v1/internal/supply_chain/container_images/#{SecureRandom.uuid}/scan",
           params: body, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/container_images/#{image.id}/scan",
           params: body, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
