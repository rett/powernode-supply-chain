# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::VendorMonitorRunner do
  let(:account) { create(:account) }

  before { allow(SupplyChainChannel).to receive(:broadcast_vendor_monitoring_event) }

  describe "#run!" do
    context "with an active vendor that needs monitoring" do
      let!(:vendor) { create(:supply_chain_vendor, :needs_assessment, account: account, status: "active") }

      it "creates monitoring events and broadcasts them" do
        expect { described_class.new(account.id).run! }
          .to change { SupplyChain::VendorMonitoringEvent.count }.by_at_least(1)

        expect(SupplyChainChannel).to have_received(:broadcast_vendor_monitoring_event).at_least(:once)
      end

      it "returns a summary hash" do
        result = described_class.new(account.id).run!

        expect(result[:accounts]).to eq(1)
        expect(result[:vendors]).to eq(1)
        expect(result[:events_created]).to be >= 1
      end
    end

    context "de-dup guard on a vendor whose contract is expiring" do
      let!(:vendor) do
        create(:supply_chain_vendor, :with_expiring_contract, :assessment_current,
               account: account, status: "active")
      end

      # Isolate the runner's own due-date checks from the shared risk service so
      # the only event source under test is the contract-expiry check + its guard.
      let(:risk_service) { instance_double(SupplyChain::VendorRiskService, monitor_vendor!: []) }

      before { allow(SupplyChain::VendorRiskService).to receive(:new).and_return(risk_service) }

      it "creates a contract-renewal event and broadcasts it on the first run" do
        expect { described_class.new(account.id).run! }
          .to change { SupplyChain::VendorMonitoringEvent.where(event_type: "contract_renewal").count }.by(1)

        expect(SupplyChainChannel).to have_received(:broadcast_vendor_monitoring_event).at_least(:once)
      end

      it "does not create a duplicate event on a second run" do
        described_class.new(account.id).run!

        expect { described_class.new(account.id).run! }
          .not_to change { SupplyChain::VendorMonitoringEvent.count }
      end
    end
  end
end
