# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::BuildProvenance", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  describe "POST /api/v1/internal/supply_chain/build_provenance/:id/verify" do
    let(:provenance) do
      create(
        :supply_chain_build_provenance,
        account: account,
        reproducibility_hash: "repro-hash",
        metadata: {
          "build_inputs" => [ { "hash" => "in-1", "verified" => true } ],
          "build_environment" => { "builder" => "github", "builder_version" => "2.311.0" },
          "build_outputs" => [ { "hash" => "out-1" } ]
        }
      )
    end

    it "verifies the provenance and returns a summary" do
      post "/api/v1/internal/supply_chain/build_provenance/#{provenance.id}/verify",
           params: { user_id: user.id }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["provenance_id"]).to eq(provenance.id)
      expect(data["status"]).to eq("verified")
      expect(data["reproducible"]).to be(true)
    end

    it "records the verification status on the provenance" do
      post "/api/v1/internal/supply_chain/build_provenance/#{provenance.id}/verify",
           params: { user_id: user.id }, headers: headers, as: :json

      expect(provenance.reload.metadata["reproducibility_status"]).to eq("verified")
    end

    it "returns 404 for an unknown provenance" do
      post "/api/v1/internal/supply_chain/build_provenance/#{SecureRandom.uuid}/verify",
           params: { user_id: user.id }, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/build_provenance/#{provenance.id}/verify",
           params: { user_id: user.id }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
