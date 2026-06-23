# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::CveMonitorRunner do
  let(:account) { create(:account) }

  before { allow(SupplyChainChannel).to receive(:broadcast_cve_alert) }

  describe "#run!" do
    context "account-wide scope with a critical vulnerability" do
      let(:monitor) { create(:supply_chain_cve_monitor, :account_wide, :all_severities, account: account) }
      let!(:sbom) { create(:supply_chain_sbom, account: account) }
      let!(:critical) { create(:supply_chain_sbom_vulnerability, :critical, sbom: sbom, account: account) }

      it "broadcasts a CVE alert" do
        described_class.new(monitor).run!
        expect(SupplyChainChannel).to have_received(:broadcast_cve_alert).at_least(:once)
      end

      it "records the run and returns a summary" do
        result = described_class.new(monitor).run!

        expect(result[:monitor_id]).to eq(monitor.id)
        expect(result[:scope_type]).to eq("account_wide")
        expect(result[:alerts_sent]).to be >= 1
        expect(monitor.reload.last_run_at).to be_present
      end
    end

    context "critical-only monitor with only a high vulnerability" do
      let(:monitor) { create(:supply_chain_cve_monitor, :account_wide, :critical_only, account: account) }
      let!(:sbom) { create(:supply_chain_sbom, account: account) }
      let!(:high) { create(:supply_chain_sbom_vulnerability, :high, sbom: sbom, account: account) }

      it "suppresses high alerts when min_severity is critical" do
        result = described_class.new(monitor).run!

        expect(result[:alerts_sent]).to eq(0)
        expect(SupplyChainChannel).not_to have_received(:broadcast_cve_alert)
      end
    end
  end
end
