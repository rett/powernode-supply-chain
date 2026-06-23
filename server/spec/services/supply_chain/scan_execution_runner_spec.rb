# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ScanExecutionRunner do
  let(:account) { create(:account) }
  let(:template) { create(:supply_chain_scan_template, :security, account: nil) }
  let(:instance) do
    create(:supply_chain_scan_instance, account: account, scan_template: template, configuration: {})
  end
  let(:sbom) { create(:supply_chain_sbom, account: account) }
  let(:execution) do
    create(:supply_chain_scan_execution,
      account: account,
      scan_instance: instance,
      status: "pending",
      input_data: { "target_type" => "SupplyChain::Sbom", "target_id" => sbom.id })
  end

  before do
    allow(SupplyChainChannel).to receive(:broadcast_execution_started)
    allow(SupplyChainChannel).to receive(:broadcast_execution_completed)
    allow(SupplyChainChannel).to receive(:broadcast_execution_failed)
  end

  describe "#run!" do
    context "security-category execution (happy path)" do
      let(:correlation_service) { instance_double(SupplyChain::VulnerabilityCorrelationService) }

      before do
        # Stub the heavy scanner — we test the runner's orchestration, not the scan.
        allow(SupplyChain::VulnerabilityCorrelationService)
          .to receive(:new).with(sbom: sbom).and_return(correlation_service)
        allow(correlation_service).to receive(:correlate!)
          .and_return({ total_vulnerabilities: 7, critical: 2, high: 5 })
      end

      it "marks the execution completed and persists the findings" do
        result = described_class.new(execution).run!

        execution.reload
        expect(execution.status).to eq("completed")
        expect(execution.completed_at).to be_present
        expect(execution.duration_ms).to be_a(Integer)
        expect(execution.output_data["findings_count"]).to eq(7)
        expect(execution.output_data["total_vulnerabilities"]).to eq(7)
        expect(result.with_indifferent_access["findings_count"]).to eq(7)
      end

      it "broadcasts started and completed but never failed" do
        described_class.new(execution).run!

        expect(SupplyChainChannel).to have_received(:broadcast_execution_started).with(execution)
        expect(SupplyChainChannel).to have_received(:broadcast_execution_completed).with(execution)
        expect(SupplyChainChannel).not_to have_received(:broadcast_execution_failed)
      end
    end

    context "when a scanner service raises (failure path)" do
      before do
        allow(SupplyChain::VulnerabilityCorrelationService)
          .to receive(:new).and_raise(StandardError.new("scanner exploded"))
      end

      it "marks the execution failed, broadcasts failed, and re-raises" do
        expect { described_class.new(execution).run! }
          .to raise_error(StandardError, "scanner exploded")

        execution.reload
        expect(execution.status).to eq("failed")
        expect(execution.error_message).to eq("scanner exploded")
        expect(SupplyChainChannel)
          .to have_received(:broadcast_execution_failed).with(execution, "scanner exploded")
        expect(SupplyChainChannel).not_to have_received(:broadcast_execution_completed)
      end
    end
  end
end
