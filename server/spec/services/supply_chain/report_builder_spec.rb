# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ReportBuilder do
  let(:account) { create(:account) }

  before do
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_started)
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_completed)
    allow(SupplyChainChannel).to receive(:broadcast_report_generation_failed)
  end

  describe "#build!" do
    context "with a compliance report (happy path)" do
      let(:report) do
        create(:supply_chain_report, account: account, report_type: "compliance", format: "json")
      end

      it "generates content, persists it, and marks the report completed" do
        described_class.new(report).build!

        report.reload
        expect(report.status).to eq("completed")
        expect(report.generated_at).to be_present
        expect(report.file_path).to be_present
        expect(report.file_size_bytes).to be > 0
        expect(report.metadata["filename"]).to eq("compliance_report.json")
        expect(report.metadata["content_type"]).to eq("application/json")
      end

      it "broadcasts generation started and completed" do
        described_class.new(report).build!

        expect(SupplyChainChannel).to have_received(:broadcast_report_generation_started).with(report)
        expect(SupplyChainChannel).to have_received(:broadcast_report_generation_completed).with(report)
      end

      it "returns the report" do
        expect(described_class.new(report).build!).to eq(report)
      end
    end

    context "when generation fails (failure path)" do
      # A valid-but-unhandled report_type drives the case/else -> raise, exercising
      # the failure branch without stubbing internals.
      let(:report) { create(:supply_chain_report, :custom, account: account) }

      it "marks the report failed, records the error, broadcasts failure, and re-raises" do
        expect { described_class.new(report).build! }.to raise_error(RuntimeError, /Unknown report type/)

        report.reload
        expect(report.status).to eq("failed")
        expect(report.metadata["error_message"]).to be_present
        expect(SupplyChainChannel).to have_received(:broadcast_report_generation_failed)
        expect(SupplyChainChannel).not_to have_received(:broadcast_report_generation_completed)
      end
    end
  end
end
