# frozen_string_literal: true

Account.class_eval do
  has_many :supply_chain_sboms, class_name: "SupplyChain::Sbom", dependent: :destroy
  has_many :supply_chain_sbom_components, through: :supply_chain_sboms, source: :components
  has_many :supply_chain_sbom_vulnerabilities, through: :supply_chain_sboms, source: :vulnerabilities
  has_many :supply_chain_vulnerability_feeds, class_name: "SupplyChain::VulnerabilityFeed", dependent: :destroy
  has_many :supply_chain_remediation_plans, class_name: "SupplyChain::RemediationPlan", dependent: :destroy
  has_many :supply_chain_signing_keys, class_name: "SupplyChain::SigningKey", dependent: :destroy
  has_many :supply_chain_attestations, class_name: "SupplyChain::Attestation", dependent: :destroy
  has_many :supply_chain_container_images, class_name: "SupplyChain::ContainerImage", dependent: :destroy
  has_many :supply_chain_image_policies, class_name: "SupplyChain::ImagePolicy", dependent: :destroy
  has_many :supply_chain_vulnerability_scans, class_name: "SupplyChain::VulnerabilityScan", dependent: :destroy
  has_many :supply_chain_cve_monitors, class_name: "SupplyChain::CveMonitor", dependent: :destroy
  has_many :supply_chain_license_policies, class_name: "SupplyChain::LicensePolicy", dependent: :destroy
  has_many :supply_chain_license_violations, class_name: "SupplyChain::LicenseViolation", dependent: :destroy
  has_many :supply_chain_vendors, class_name: "SupplyChain::Vendor", dependent: :destroy
  has_many :supply_chain_risk_assessments, class_name: "SupplyChain::RiskAssessment", dependent: :destroy
  has_many :supply_chain_questionnaire_templates, class_name: "SupplyChain::QuestionnaireTemplate", dependent: :destroy
  has_many :supply_chain_vendor_monitoring_events, class_name: "SupplyChain::VendorMonitoringEvent", dependent: :destroy
  has_many :supply_chain_scan_templates, class_name: "SupplyChain::ScanTemplate", dependent: :destroy
  has_many :supply_chain_scan_instances, class_name: "SupplyChain::ScanInstance", dependent: :destroy
  has_many :supply_chain_scan_executions, class_name: "SupplyChain::ScanExecution", dependent: :destroy
  has_many :supply_chain_reports, class_name: "SupplyChain::Report", dependent: :destroy
  has_many :supply_chain_attributions, class_name: "SupplyChain::Attribution", dependent: :destroy
  has_many :supply_chain_license_detections, class_name: "SupplyChain::LicenseDetection", dependent: :destroy
  has_many :supply_chain_build_provenances, class_name: "SupplyChain::BuildProvenance", dependent: :destroy
end
