# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::VendorMonitoringJob, type: :job do
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
    let(:endpoint) { "/api/v1/internal/supply_chain/vendors/monitor" }

    context "with an account id" do
      let(:account_id) { SecureRandom.uuid }

      it "POSTs the monitor endpoint with the account_id and returns the data payload" do
        allow(api_client).to receive(:post)
          .with(endpoint, { account_id: account_id })
          .and_return("data" => { "accounts" => 1, "vendors" => 3, "events_created" => 2 })

        result = job.execute(account_id)

        expect(api_client).to have_received(:post).with(endpoint, { account_id: account_id })
        expect(result).to include("events_created" => 2)
      end
    end

    context "without an account id (sweep all accounts)" do
      it "POSTs the monitor endpoint with a nil account_id" do
        allow(api_client).to receive(:post)
          .with(endpoint, { account_id: nil })
          .and_return("data" => { "accounts" => 5, "vendors" => 12, "events_created" => 7 })

        result = job.execute

        expect(api_client).to have_received(:post).with(endpoint, { account_id: nil })
        expect(result).to include("accounts" => 5)
      end
    end

    context "when the server returns a non-hash body" do
      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(SecureRandom.uuid)).to eq({})
      end
    end

    context "when the API errors" do
      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(SecureRandom.uuid) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
