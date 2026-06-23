# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::SbomGenerationJob, type: :job do
  subject { described_class }

  it_behaves_like "a base job", described_class
  it_behaves_like "a job with API communication"

  let(:job) { described_class.new }
  let(:api_client) { instance_double(BackendApiClient) }

  before { allow(job).to receive(:api_client).and_return(api_client) }

  describe "queue configuration" do
    it "uses the supply_chain_default queue" do
      expect(described_class.sidekiq_options["queue"]).to eq("supply_chain_default")
    end
  end

  describe "#execute" do
    let(:account_id) { SecureRandom.uuid }
    let(:repository_id) { SecureRandom.uuid }
    let(:options) do
      { "source_path" => "/tmp/repo", "ecosystems" => [ "npm" ], "format" => "cyclonedx_1_5" }
    end
    let(:endpoint) { "/api/v1/internal/supply_chain/sboms/generate" }
    let(:body) { { account_id: account_id, repository_id: repository_id, options: options } }

    it "POSTs the generate endpoint with account, repository and options and returns the data payload" do
      allow(api_client).to receive(:post)
        .with(endpoint, body)
        .and_return("data" => { "sbom_id" => "sbom-123" })

      result = job.execute(account_id, repository_id, options)

      expect(api_client).to have_received(:post).with(endpoint, body)
      expect(result).to include("sbom_id" => "sbom-123")
    end

    it "defaults options to an empty hash when omitted" do
      expected = { account_id: account_id, repository_id: repository_id, options: {} }
      allow(api_client).to receive(:post).with(endpoint, expected).and_return("data" => {})

      job.execute(account_id, repository_id)

      expect(api_client).to have_received(:post).with(endpoint, expected)
    end

    context "when the server returns a non-hash body" do
      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(account_id, repository_id, options)).to eq({})
      end
    end

    context "when the API errors" do
      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(account_id, repository_id, options) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
