# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ReproducibilityVerifier do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  # Spy on the user-notification path (core model's account/user-scoped API).
  before { allow(Notification).to receive(:create_for_user) }

  describe "#verify!" do
    context "when the build is reproducible" do
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

      it "marks the provenance verified and returns a reproducible summary" do
        result = described_class.new(provenance, user).verify!

        expect(result[:provenance_id]).to eq(provenance.id)
        expect(result[:status]).to eq("verified")
        expect(result[:reproducible]).to be(true)

        provenance.reload
        expect(provenance.metadata["reproducibility_status"]).to eq("verified")
        expect(provenance.reproducible?).to be(true)
        expect(provenance.reproducibility_verified_at).to be_present
      end

      it "notifies the user of the success" do
        described_class.new(provenance, user).verify!

        expect(Notification).to have_received(:create_for_user)
          .with(user, type: "verification_success", title: anything, message: anything)
      end

      it "does not notify when no user is given" do
        described_class.new(provenance, nil).verify!
        expect(Notification).not_to have_received(:create_for_user)
      end
    end

    context "when the build is not reproducible" do
      let(:provenance) do
        create(
          :supply_chain_build_provenance,
          account: account,
          metadata: {
            # blank hash → fails verify_inputs
            "build_inputs" => [ { "hash" => "", "verified" => true } ]
          }
        )
      end

      it "marks the provenance failed with errors and returns a non-reproducible summary" do
        result = described_class.new(provenance, user).verify!

        expect(result[:status]).to eq("failed")
        expect(result[:reproducible]).to be(false)

        provenance.reload
        expect(provenance.metadata["reproducibility_status"]).to eq("failed")
        expect(provenance.metadata["verification_errors"])
          .to include("Build inputs do not match recorded provenance")
      end

      it "notifies the user of the failure" do
        described_class.new(provenance, user).verify!

        expect(Notification).to have_received(:create_for_user)
          .with(user, type: "verification_failed", title: anything, message: anything)
      end
    end
  end
end
