# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplyChain::ContainerScanJob, type: :job do
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
    let(:container_image_id) { SecureRandom.uuid }
    let(:options) { { "scanner" => "trivy", "evaluate_policies" => true } }
    let(:endpoint) { "/api/v1/internal/supply_chain/container_images/#{container_image_id}/scan" }

    it "POSTs the scan endpoint with the options body and returns the data payload" do
      allow(api_client).to receive(:post)
        .with(endpoint, { options: options })
        .and_return("data" => { "scan_id" => "scan-1", "vulnerability_counts" => { "critical" => 2 } })

      result = job.execute(container_image_id, options)

      expect(api_client).to have_received(:post).with(endpoint, { options: options })
      expect(result).to include("scan_id" => "scan-1")
    end

    it "defaults options to an empty hash" do
      allow(api_client).to receive(:post)
        .with(endpoint, { options: {} })
        .and_return("data" => {})

      job.execute(container_image_id)

      expect(api_client).to have_received(:post).with(endpoint, { options: {} })
    end

    context "when the server returns a non-hash body" do
      it "returns an empty hash" do
        allow(api_client).to receive(:post).and_return(nil)
        expect(job.execute(container_image_id, options)).to eq({})
      end
    end

    context "when the API errors" do
      it "propagates the error so Sidekiq retries" do
        allow(api_client).to receive(:post)
          .and_raise(BackendApiClient::ApiError.new("backend down", 503))

        expect { job.execute(container_image_id, options) }.to raise_error(BackendApiClient::ApiError)
      end
    end
  end
end
