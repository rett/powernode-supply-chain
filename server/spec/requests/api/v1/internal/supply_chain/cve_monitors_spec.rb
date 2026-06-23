# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Internal::SupplyChain::CveMonitors", type: :request do
  let(:account) { create(:account) }
  let(:worker) { create(:worker, account: account) }
  let(:headers) do
    { "X-Forwarded-Tls-Client-Cert-Info" => CGI.escape(%(Subject="CN=#{worker.node_instance_id}")) }
  end

  before { allow(SupplyChainChannel).to receive(:broadcast_cve_alert) }

  describe "POST /api/v1/internal/supply_chain/cve_monitors/:id/run" do
    let(:monitor) { create(:supply_chain_cve_monitor, :account_wide, :all_severities, account: account) }
    let!(:sbom) { create(:supply_chain_sbom, account: account, status: "completed") }
    let!(:vuln) { create(:supply_chain_sbom_vulnerability, :critical, sbom: sbom, account: account) }

    it "runs the monitor and returns a summary" do
      post "/api/v1/internal/supply_chain/cve_monitors/#{monitor.id}/run", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["monitor_id"]).to eq(monitor.id)
      expect(data["alerts_sent"]).to be >= 1
    end

    it "broadcasts CVE alerts" do
      post "/api/v1/internal/supply_chain/cve_monitors/#{monitor.id}/run", headers: headers, as: :json
      expect(SupplyChainChannel).to have_received(:broadcast_cve_alert).at_least(:once)
    end

    it "records the run timestamp" do
      expect do
        post "/api/v1/internal/supply_chain/cve_monitors/#{monitor.id}/run", headers: headers, as: :json
      end.to change { monitor.reload.last_run_at }
    end

    it "returns 404 for an unknown monitor" do
      post "/api/v1/internal/supply_chain/cve_monitors/#{SecureRandom.uuid}/run", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "rejects callers without a valid worker mTLS cert" do
      post "/api/v1/internal/supply_chain/cve_monitors/#{monitor.id}/run", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/internal/supply_chain/cve_monitors/run_all" do
    let!(:active_monitor) { create(:supply_chain_cve_monitor, :account_wide, account: account, is_active: true) }
    let!(:inactive_monitor) { create(:supply_chain_cve_monitor, :inactive, account: account) }

    it "runs every active monitor and returns the aggregate" do
      post "/api/v1/internal/supply_chain/cve_monitors/run_all", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["monitors_run"]).to be >= 1
    end
  end
end
