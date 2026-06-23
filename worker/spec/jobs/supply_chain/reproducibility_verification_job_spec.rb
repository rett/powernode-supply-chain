# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ReproducibilityVerificationJob, type: :job do
  subject { described_class }

  it_behaves_like "a base job", described_class
  it_behaves_like "a job with API communication"

  let(:job) { described_class.new }
  let(:api_client) { instance_double(BackendApiClient) }

  before { allow(job).to receive(:api_client).and_return(api_client) }

  describe "queue configuration" do
    it "uses the default queue" do
      expect(described_class.sidekiq_options["queue"]).to eq("default")
    end
  end

  describe "#execute" do
    let(:provenance_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }
    let(:endpoint) { "/api/v1/internal/supply_chain/build_provenance/#{provenance_id}/verify" }

    it "POSTs the verify endpoint with the user_id and returns the data payload" do
      allow(api_client).to receive(:post)
        .with(endpoint, { user_id: user_id })
        .and_return("data" => { "provenance_id" => provenance_id, "status" => "verified", "reproducible" => true })

      result = job.execute(provenance_id, user_id)

      expect(api_client).to have_received(:post).with(endpoint, { user_id: user_id })
      expect(result).to include("status" => "verified", "reproducible" => true)
    end

    context "when the server returns a non-hash body" do
      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(provenance_id, user_id)).to eq({})
      end
    end

    context "when the API errors" do
      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(provenance_id, user_id) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
