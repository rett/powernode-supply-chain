# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::Vendors", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  before { allow(SupplyChainChannel).to receive(:broadcast_vendor_monitoring_event) }

  describe "POST /api/v1/internal/supply_chain/vendors/monitor" do
    let!(:vendor) { create(:supply_chain_vendor, :needs_assessment, account: account, status: "active") }

    it "monitors the account's vendors and returns a summary" do
      post "/api/v1/internal/supply_chain/vendors/monitor",
           params: { account_id: account.id }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["accounts"]).to eq(1)
      expect(data["vendors"]).to be >= 1
      expect(data["events_created"]).to be >= 1
    end

    it "broadcasts vendor monitoring events" do
      post "/api/v1/internal/supply_chain/vendors/monitor",
           params: { account_id: account.id }, headers: headers, as: :json

      expect(SupplyChainChannel).to have_received(:broadcast_vendor_monitoring_event).at_least(:once)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/vendors/monitor",
           params: { account_id: account.id }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
