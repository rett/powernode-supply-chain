# frozen_string_literal: true

require "rails_helper"

# The supply-chain extension contributes the SBOM association + the polymorphic
# file-attachable resolvers that were removed from core (IMP-affa1c163adc).
RSpec.describe "supply-chain GitRepository decorator + attachable registration" do
  let(:account) { create(:account) }

  describe "Devops::GitRepository#sboms (decorator)" do
    it "exposes the sboms association when the extension is loaded" do
      repo = create(:git_repository, account: account)
      sbom = create(:supply_chain_sbom, account: account, repository: repo)

      expect(repo.sboms).to include(sbom)
    end

    it "nullifies git_repository_id on dependent sboms when the repo is destroyed" do
      repo = create(:git_repository, account: account)
      sbom = create(:supply_chain_sbom, account: account, repository: repo)

      repo.destroy!

      expect(sbom.reload.git_repository_id).to be_nil
    end
  end

  describe "Powernode::AttachableRegistry registration" do
    {
      "SupplyChain::Sbom" => :supply_chain_sboms,
      "SupplyChain::Attestation" => :supply_chain_attestations,
      "SupplyChain::ContainerImage" => :supply_chain_container_images,
      "SupplyChain::Vendor" => :supply_chain_vendors
    }.each do |type, association|
      it "registers a resolver for #{type}" do
        expect(Powernode::AttachableRegistry.resolve(type)).to respond_to(:call)
        expect(account).to respond_to(association)
      end
    end

    it "resolves an SBOM through the registered resolver, scoped to the account" do
      sbom = create(:supply_chain_sbom, account: account)
      resolver = Powernode::AttachableRegistry.resolve("SupplyChain::Sbom")

      expect(resolver.call(account, sbom.id)).to eq(sbom)
      expect(resolver.call(create(:account), sbom.id)).to be_nil
    end
  end
end
