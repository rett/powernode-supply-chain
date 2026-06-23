# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::CveMonitoringJob, type: :job do
  subject { described_class }

  it_behaves_like "a base job", described_class
  it_behaves_like "a job with API communication"

  let(:job) { described_class.new }
  let(:api_client) { instance_double(BackendApiClient) }

  before { allow(job).to receive(:api_client).and_return(api_client) }

  describe "queue configuration" do
    it "uses the supply_chain_monitoring queue" do
      expect(described_class.sidekiq_options["queue"]).to eq("supply_chain_monitoring")
    end
  end

  describe "#execute" do
    context "with a monitor id" do
      let(:monitor_id) { SecureRandom.uuid }
      let(:endpoint) { "/api/v1/internal/supply_chain/cve_monitors/#{monitor_id}/run" }

      it "POSTs the monitor run endpoint and returns the data payload" do
        allow(api_client).to receive(:post)
          .with(endpoint, {})
          .and_return("data" => { "monitor_id" => monitor_id, "alerts_sent" => 2 })

        result = job.execute(monitor_id)

        expect(api_client).to have_received(:post).with(endpoint, {})
        expect(result).to include("alerts_sent" => 2)
      end
    end

    context "without a monitor id (sweep all active monitors)" do
      let(:endpoint) { "/api/v1/internal/supply_chain/cve_monitors/run_all" }

      it "POSTs the run_all endpoint" do
        allow(api_client).to receive(:post)
          .with(endpoint, {})
          .and_return("data" => { "monitors_run" => 3, "alerts_sent" => 5 })

        result = job.execute

        expect(api_client).to have_received(:post).with(endpoint, {})
        expect(result).to include("monitors_run" => 3)
      end
    end

    context "when the server returns a non-hash body" do
      let(:monitor_id) { SecureRandom.uuid }

      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(monitor_id)).to eq({})
      end
    end

    context "when the API errors" do
      let(:monitor_id) { SecureRandom.uuid }

      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(monitor_id) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
