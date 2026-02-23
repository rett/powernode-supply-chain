# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "powernode_supply_chain"
  spec.version       = "0.1.0"
  spec.authors       = ["Powernode"]
  spec.summary       = "Supply Chain Security extension for Powernode"
  spec.description   = "SBOM management, vulnerability scanning, container security, attestations, vendor risk, and license compliance."
  spec.license       = "Proprietary"

  spec.files         = Dir["{app,config,db,lib}/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 8.0"
end
