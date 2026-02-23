# frozen_string_literal: true

module PowernodeSupplyChain
  class Engine < ::Rails::Engine
    isolate_namespace PowernodeSupplyChain

    # Add extension directories to autoload paths
    initializer "powernode_supply_chain.autoload", before: :set_autoload_paths do |app|
      %w[models services controllers channels].each do |subdir|
        path = root.join("app", subdir)
        app.config.autoload_paths << path.to_s if path.exist?
      end
    end

    # Load decorators that extend core models
    config.to_prepare do
      Dir[PowernodeSupplyChain::Engine.root.join("app", "decorators", "**", "*_decorator.rb")].each do |decorator|
        load decorator
      end
    end

    # Add extension migrations to the application migration paths
    initializer "powernode_supply_chain.migrations" do |app|
      path = root.join("db", "migrate")
      app.config.paths["db/migrate"] << path.to_s if path.exist?
    end

    # Register with the dynamic extension registry
    initializer "powernode_supply_chain.register", after: :load_config_initializers do
      config.after_initialize do
        Powernode::ExtensionRegistry.register(
          slug: "supply-chain",
          engine: PowernodeSupplyChain::Engine,
          version: PowernodeSupplyChain::VERSION
        )
      end
    end

    # Register supply chain step handlers with the DevOps StepHandlerRegistry
    initializer "powernode_supply_chain.step_handlers", after: :load_config_initializers do
      config.after_initialize do
        if defined?(Devops::StepHandlerRegistry)
          {
            "sbom_generate" => "Devops::StepHandlers::SbomGenerateHandler",
            "vulnerability_scan" => "Devops::StepHandlers::VulnerabilityScanHandler",
            "sign_artifact" => "Devops::StepHandlers::SignArtifactHandler",
            "policy_gate" => "Devops::StepHandlers::PolicyGateHandler",
            "compliance_export" => "Devops::StepHandlers::ComplianceExportHandler",
            "remediation_plan" => "Devops::StepHandlers::RemediationPlanHandler",
            "generate_attestation" => "Devops::StepHandlers::GenerateAttestationHandler"
          }.each do |type, handler|
            Devops::StepHandlerRegistry.register(type, handler, extension: "supply-chain")
          end
        end
      end
    end
  end
end
