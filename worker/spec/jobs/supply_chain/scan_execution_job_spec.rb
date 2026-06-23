# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ScanExecutionJob, type: :job do
  subject { described_class }

  it_behaves_like "a base job", described_class
  it_behaves_like "a job with API communication"

  let(:job) { described_class.new }
  let(:api_client) { instance_double(BackendApiClient) }

  before { allow(job).to receive(:api_client).and_return(api_client) }

  describe "queue configuration" do
    it "uses the supply_chain_scans queue" do
      expect(described_class.sidekiq_options["queue"]).to eq("supply_chain_scans")
    end
  end

  describe "#execute" do
    let(:execution_id) { SecureRandom.uuid }
    let(:endpoint) { "/api/v1/internal/supply_chain/scan_executions/#{execution_id}/run" }

    it "POSTs the scan-execution run endpoint and returns the data payload" do
      allow(api_client).to receive(:post)
        .with(endpoint, {})
        .and_return("data" => {
          "execution_id" => execution_id,
          "status" => "completed",
          "output_data" => { "findings_count" => 5 }
        })

      result = job.execute(execution_id)

      expect(api_client).to have_received(:post).with(endpoint, {})
      expect(result).to include("status" => "completed")
    end

    context "when the server returns a non-hash body" do
      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(execution_id)).to eq({})
      end
    end

    context "when the API errors" do
      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(execution_id) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
