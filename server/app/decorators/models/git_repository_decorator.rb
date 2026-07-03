# frozen_string_literal: true

# Contributes the supply-chain SBOM association onto the core Devops::GitRepository
# model. Core owns the repository; the OPTIONAL supply-chain extension owns the
# SupplyChain:: namespace, so this reverse-dependency lives here (mirrors
# account_decorator.rb). Loaded via the engine's config.to_prepare.
Devops::GitRepository.class_eval do
  has_many :sboms, class_name: "SupplyChain::Sbom", foreign_key: "git_repository_id", dependent: :nullify
end
