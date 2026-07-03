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
    end    # Tell Zeitwerk to ignore the decorators directory entirely. Files
    # under app/decorators use Class.class_eval and don't define a constant
    # matching their path — eager_load_all in production raises Zeitwerk::NameError
    # without this. Mirrors the fix in extensions/system's engine.
    initializer "#powernode_supply_chain.ignore_decorators", before: :set_autoload_paths do |_app|
      decorators_path = root.join("app", "decorators")
      Rails.autoloaders.main.ignore(decorators_path.to_s) if decorators_path.exist?
    end



    # Load decorators that extend core models — explicit via load (path-based, not autoload).
    config.to_prepare do
      Dir[PowernodeSupplyChain::Engine.root.join("app", "decorators", "**", "*_decorator.rb")].each do |decorator|
        load decorator
      end
    end

    # Register this extension's polymorphic file attachable types with the core
    # Powernode::AttachableRegistry seam (core owns only "Page"). Uses to_prepare
    # so registration re-applies on every dev reload — the registry's resolver
    # store is reset when the core class reloads. Each resolver reads the
    # account_decorator's supply_chain_* associations at request time.
    config.to_prepare do
      if defined?(::Powernode::AttachableRegistry)
        {
          "SupplyChain::Sbom" => :supply_chain_sboms,
          "SupplyChain::Attestation" => :supply_chain_attestations,
          "SupplyChain::ContainerImage" => :supply_chain_container_images,
          "SupplyChain::Vendor" => :supply_chain_vendors
        }.each do |type, association|
          ::Powernode::AttachableRegistry.register(type) do |account, id|
            account.public_send(association).find_by(id: id)
          end
        end
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

    # Register supply-chain permissions + role grants via the catalog DSL.
    # Replaces the retired imperative db/seeds/supply_chain_permissions.rb (whose
    # role grants Role#sync_permissions! wiped on every db:seed anyway). The coarse
    # read/write/admin tiers match controller enforcement; signing_keys.manage is a
    # crypto-custodian carve-out (key create/rotate/revoke) NOT given to manager.
    initializer "powernode_supply_chain.register_permissions", after: :load_config_initializers do
      config.after_initialize do
        next unless defined?(::Permissions) && ::Permissions.respond_to?(:register_catalog)

        ::Permissions.register_catalog(namespace: "supply_chain") do
          permission "supply_chain.read", "View all supply chain data (SBOMs, scans, vendors, licenses, attestations)",
                     grant: { owner: true, admin: true, manager: true, member: true }
          permission "supply_chain.write", "Manage supply chain data (create/update/scan/assess)",
                     grant: { owner: true, admin: true, manager: true }
          permission "supply_chain.admin", "Administer supply chain settings, sync feeds, approve exceptions",
                     grant: { owner: true, admin: true }
          # Crypto custodian — signing-key lifecycle; NOT granted to manager.
          resource :signing_keys, actions: %i[manage], grant: { owner: :all, admin: :all }
        end
      end
    end

    # Register this extension's audit ACTIONS via the AuditActions seam (the
    # audit twin of register_catalog). The supply_chain.* action tokens were
    # relocated out of core's AuditActions concern — they are emitted by the
    # supply-chain API controllers' log_audit_event(...) calls. AuditLog#action
    # validates against the dynamic AuditActions.all_actions union, so once this
    # runs at boot those audit rows validate. supply-chain is a public extension
    # (always loaded unless explicitly disabled), so these are registered in
    # both core and full modes.
    initializer "powernode_supply_chain.register_audit_actions", after: :load_config_initializers do
      config.after_initialize do
        next unless defined?(::AuditActions) && ::AuditActions.respond_to?(:register_actions)

        supply_chain_actions = %w[
          supply_chain.attestations.create supply_chain.attestations.delete supply_chain.attestations.read
          supply_chain.attestations.record_to_rekor supply_chain.attestations.sign supply_chain.attestations.update
          supply_chain.attestations.verify
          supply_chain.container_images.create supply_chain.container_images.delete supply_chain.container_images.evaluate_policies
          supply_chain.container_images.quarantine supply_chain.container_images.read supply_chain.container_images.scan
          supply_chain.container_images.update supply_chain.container_images.verify
          supply_chain.reports.create supply_chain.reports.delete supply_chain.reports.download
          supply_chain.reports.generate_attribution supply_chain.reports.generate_compliance supply_chain.reports.generate_sbom
          supply_chain.reports.generate_vendor_risk supply_chain.reports.generate_vulnerability supply_chain.reports.read
          supply_chain.reports.regenerate supply_chain.reports.update
          supply_chain.sboms.calculate_risk supply_chain.sboms.correlate_vulnerabilities supply_chain.sboms.create
          supply_chain.sboms.delete supply_chain.sboms.export supply_chain.sboms.read supply_chain.sboms.rescan
          supply_chain.sboms.update
          supply_chain.vendors.assess supply_chain.vendors.create supply_chain.vendors.delete
          supply_chain.vendors.read supply_chain.vendors.reassess supply_chain.vendors.update
        ]

        ::AuditActions.register_actions("supply_chain", supply_chain_actions)
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
