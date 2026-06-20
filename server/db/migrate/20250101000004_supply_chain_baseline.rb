# frozen_string_literal: true
class SupplyChainBaseline < ActiveRecord::Migration[8.1]
  def change
  # These are extensions that must be enabled in order to support this database

  create_table "supply_chain_attestations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "attestation_id", null: false
    t.string "attestation_type", default: "slsa_provenance", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "pipeline_run_id"
    t.jsonb "predicate", default: {}, null: false
    t.string "predicate_type", null: false
    t.string "rekor_log_id"
    t.string "rekor_log_url"
    t.datetime "rekor_logged_at"
    t.uuid "sbom_id"
    t.text "signature"
    t.string "signature_algorithm"
    t.string "signature_format", default: "dsse"
    t.uuid "signing_key_id"
    t.integer "slsa_level", default: 1
    t.string "subject_digest", null: false
    t.string "subject_digest_algorithm", default: "sha256", null: false
    t.string "subject_name", null: false
    t.datetime "updated_at", null: false
    t.jsonb "verification_results", default: {}, null: false
    t.string "verification_status", default: "unverified", null: false
    t.datetime "verified_at"
    t.index ["account_id", "attestation_id"], unique: true
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["pipeline_run_id"]
    t.index ["predicate"], name: "idx_attestations_predicate", using: :gin
    t.index ["sbom_id"]
    t.index ["signing_key_id"]
    t.index ["subject_digest"]
    t.index ["verification_status"]
    t.check_constraint "attestation_type::text = ANY (ARRAY['slsa_provenance'::character varying::text, 'sbom'::character varying::text, 'vuln_scan'::character varying::text, 'custom'::character varying::text])", name: "check_attestations_type"
    t.check_constraint "slsa_level = ANY (ARRAY[0, 1, 2, 3])", name: "check_attestations_slsa_level"
    t.check_constraint "verification_status::text = ANY (ARRAY['unverified'::character varying::text, 'verified'::character varying::text, 'failed'::character varying::text, 'expired'::character varying::text])", name: "check_attestations_verification_status"
  end

  create_table "supply_chain_attributions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "attribution_url"
    t.string "copyright_holder"
    t.integer "copyright_year"
    t.datetime "created_at", null: false
    t.uuid "license_id"
    t.text "license_text"
    t.jsonb "metadata", default: {}, null: false
    t.text "notice_text"
    t.string "package_name", null: false
    t.string "package_version"
    t.boolean "requires_attribution", default: true, null: false
    t.boolean "requires_license_copy", default: false, null: false
    t.boolean "requires_source_disclosure", default: false, null: false
    t.uuid "sbom_component_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"]
    t.index ["license_id"]
    t.index ["sbom_component_id"], unique: true
  end

  create_table "supply_chain_build_provenances", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "attestation_id", null: false
    t.jsonb "build_config", default: {}, null: false
    t.integer "build_duration_ms"
    t.datetime "build_finished_at"
    t.datetime "build_started_at"
    t.string "builder_id", null: false
    t.string "builder_version"
    t.datetime "created_at", null: false
    t.jsonb "environment", default: {}, null: false
    t.jsonb "invocation", default: {}, null: false
    t.jsonb "materials", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reproducibility_hash"
    t.datetime "reproducibility_verified_at"
    t.boolean "reproducible", default: false, null: false
    t.string "source_branch"
    t.string "source_commit"
    t.string "source_repository"
    t.datetime "updated_at", null: false
    t.index ["account_id"]
    t.index ["attestation_id"], unique: true
    t.index ["builder_id"]
    t.index ["materials"], name: "idx_build_provenance_materials", using: :gin
  end

  create_table "supply_chain_container_images", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "architecture"
    t.uuid "attestation_id"
    t.uuid "base_image_id"
    t.datetime "created_at", null: false
    t.integer "critical_vuln_count", default: 0, null: false
    t.jsonb "deployment_contexts", default: [], null: false
    t.string "digest", null: false
    t.integer "high_vuln_count", default: 0, null: false
    t.boolean "is_deployed", default: false, null: false
    t.boolean "is_signed", default: false, null: false
    t.jsonb "labels", default: {}, null: false
    t.datetime "last_scanned_at"
    t.jsonb "layers", default: [], null: false
    t.integer "low_vuln_count", default: 0, null: false
    t.integer "medium_vuln_count", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "os"
    t.datetime "pushed_at"
    t.string "registry", null: false
    t.string "repository", null: false
    t.uuid "sbom_id"
    t.bigint "size_bytes", default: 0
    t.string "status", default: "unverified", null: false
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["account_id", "digest"], unique: true
    t.index ["account_id"]
    t.index ["attestation_id"]
    t.index ["base_image_id"]
    t.index ["is_deployed"]
    t.index ["labels"], name: "idx_container_images_labels", using: :gin
    t.index ["registry", "repository", "tag"]
    t.index ["sbom_id"]
    t.index ["status"]
    t.check_constraint "status::text = ANY (ARRAY['unverified'::character varying::text, 'verified'::character varying::text, 'quarantined'::character varying::text, 'approved'::character varying::text, 'rejected'::character varying::text])", name: "check_container_images_status"
  end

  create_table "supply_chain_cve_monitors", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.jsonb "filters", default: {}, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_run_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "min_severity", default: "medium", null: false
    t.string "name", null: false
    t.datetime "next_run_at"
    t.jsonb "notification_channels", default: [], null: false
    t.string "schedule_cron"
    t.uuid "scope_id"
    t.string "scope_type", default: "account_wide", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], unique: true
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["is_active"]
    t.index ["next_run_at"]
    t.index ["scope_type", "scope_id"]
    t.check_constraint "min_severity::text = ANY (ARRAY['critical'::character varying::text, 'high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text])", name: "check_cve_monitors_severity"
    t.check_constraint "scope_type::text = ANY (ARRAY['image'::character varying::text, 'repository'::character varying::text, 'account_wide'::character varying::text])", name: "check_cve_monitors_scope"
  end

  create_table "supply_chain_image_policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.string "enforcement_level", default: "warn", null: false
    t.boolean "is_active", default: true, null: false
    t.jsonb "match_rules", default: {}, null: false
    t.integer "max_critical_vulns"
    t.integer "max_high_vulns"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "policy_type", default: "registry_allowlist", null: false
    t.integer "priority", default: 0, null: false
    t.boolean "require_sbom", default: false, null: false
    t.boolean "require_signature", default: false, null: false
    t.jsonb "rules", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], unique: true
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["is_active"]
    t.index ["policy_type"]
    t.check_constraint "enforcement_level::text = ANY (ARRAY['log'::character varying::text, 'warn'::character varying::text, 'block'::character varying::text])", name: "check_image_policies_enforcement"
    t.check_constraint "policy_type::text = ANY (ARRAY['registry_allowlist'::character varying::text, 'signature_required'::character varying::text, 'vulnerability_threshold'::character varying::text, 'custom'::character varying::text])", name: "check_image_policies_type"
  end

  create_table "supply_chain_license_detections", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "ai_interpretation", default: {}, null: false
    t.decimal "confidence_score", precision: 5, scale: 4, default: "1.0"
    t.datetime "created_at", null: false
    t.string "detected_license_id"
    t.string "detected_license_name"
    t.string "detection_source", default: "manifest", null: false
    t.string "file_path"
    t.boolean "is_primary", default: true, null: false
    t.uuid "license_id"
    t.text "license_text_snippet"
    t.jsonb "metadata", default: {}, null: false
    t.boolean "requires_review", default: false, null: false
    t.uuid "sbom_component_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"]
    t.index ["detection_source"]
    t.index ["license_id"]
    t.index ["sbom_component_id"]
  end

  create_table "supply_chain_license_policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "allowed_licenses", default: [], null: false
    t.boolean "block_copyleft", default: false, null: false
    t.boolean "block_strong_copyleft", default: true, null: false
    t.boolean "block_unknown", default: false, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.jsonb "denied_licenses", default: [], null: false
    t.text "description"
    t.string "enforcement_level", default: "warn", null: false
    t.jsonb "exception_packages", default: [], null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "policy_type", default: "allowlist", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], unique: true
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["is_active"]
    t.index ["is_default"], name: "idx_license_policies_default", where: "(is_default = true)"
    t.check_constraint "enforcement_level::text = ANY (ARRAY['log'::character varying::text, 'warn'::character varying::text, 'block'::character varying::text])", name: "check_license_policies_enforcement"
    t.check_constraint "policy_type::text = ANY (ARRAY['allowlist'::character varying::text, 'denylist'::character varying::text, 'hybrid'::character varying::text])", name: "check_license_policies_type"
  end

  create_table "supply_chain_license_violations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "ai_remediation", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "exception_approved_at"
    t.uuid "exception_approved_by_id"
    t.datetime "exception_expires_at"
    t.text "exception_reason"
    t.boolean "exception_requested", default: false, null: false
    t.string "exception_status"
    t.uuid "license_id"
    t.uuid "license_policy_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.uuid "sbom_component_id", null: false
    t.uuid "sbom_id", null: false
    t.string "severity", default: "high", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.string "violation_type", default: "denied", null: false
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["exception_approved_by_id"]
    t.index ["license_id"]
    t.index ["license_policy_id"]
    t.index ["sbom_component_id"]
    t.index ["sbom_id"]
    t.index ["violation_type"]
    t.check_constraint "severity::text = ANY (ARRAY['critical'::character varying::text, 'high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text])", name: "check_license_violations_severity"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying::text, 'reviewing'::character varying::text, 'resolved'::character varying::text, 'exception_granted'::character varying::text, 'wont_fix'::character varying::text])", name: "check_license_violations_status"
    t.check_constraint "violation_type::text = ANY (ARRAY['denied'::character varying::text, 'copyleft'::character varying::text, 'incompatible'::character varying::text, 'unknown'::character varying::text, 'expired'::character varying::text])", name: "check_license_violations_type"
  end

  create_table "supply_chain_licenses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "category", default: "unknown", null: false
    t.jsonb "compatibility", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "detection_patterns", default: [], null: false
    t.boolean "is_copyleft", default: false, null: false
    t.boolean "is_deprecated", default: false, null: false
    t.boolean "is_network_copyleft", default: false, null: false
    t.boolean "is_osi_approved", default: false, null: false
    t.boolean "is_strong_copyleft", default: false, null: false
    t.text "license_text"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "spdx_id", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["category"]
    t.index ["is_copyleft"]
    t.index ["spdx_id"], unique: true
    t.check_constraint "category::text = ANY (ARRAY['permissive'::character varying::text, 'copyleft'::character varying::text, 'weak_copyleft'::character varying::text, 'public_domain'::character varying::text, 'proprietary'::character varying::text, 'unknown'::character varying::text])", name: "check_licenses_category"
  end

  create_table "supply_chain_questionnaire_responses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "access_token", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}, null: false
    t.decimal "overall_score", precision: 5, scale: 2
    t.uuid "requested_by_id"
    t.jsonb "responses", default: {}, null: false
    t.text "review_notes"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.uuid "risk_assessment_id"
    t.jsonb "section_scores", default: {}, null: false
    t.datetime "sent_at"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "submitted_at"
    t.uuid "template_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "vendor_id", null: false
    t.index ["access_token"], unique: true
    t.index ["account_id"]
    t.index ["requested_by_id"]
    t.index ["reviewed_by_id"]
    t.index ["risk_assessment_id"]
    t.index ["status"]
    t.index ["template_id"]
    t.index ["vendor_id", "template_id"]
    t.index ["vendor_id"]
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'in_progress'::character varying::text, 'submitted'::character varying::text, 'reviewed'::character varying::text, 'expired'::character varying::text])", name: "check_questionnaire_responses_status"
  end

  create_table "supply_chain_questionnaire_templates", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.boolean "is_system", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.jsonb "questions", default: [], null: false
    t.jsonb "sections", default: [], null: false
    t.string "template_type", default: "custom", null: false
    t.datetime "updated_at", null: false
    t.string "version", default: "1.0", null: false
    t.index ["account_id", "name"], name: "idx_questionnaire_templates_account_name", unique: true, where: "(account_id IS NOT NULL)"
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["is_system"]
    t.index ["template_type"]
    t.check_constraint "template_type::text = ANY (ARRAY['soc2'::character varying::text, 'iso27001'::character varying::text, 'gdpr'::character varying::text, 'hipaa'::character varying::text, 'pci_dss'::character varying::text, 'custom'::character varying::text])", name: "check_questionnaire_templates_type"
  end

  create_table "supply_chain_remediation_plans", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "approval_status", default: "pending"
    t.datetime "approved_at"
    t.uuid "approved_by_id"
    t.boolean "auto_executable", default: false, null: false
    t.jsonb "breaking_changes", default: [], null: false
    t.decimal "confidence_score", precision: 5, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.string "generated_pr_url"
    t.jsonb "metadata", default: {}, null: false
    t.string "plan_type", default: "manual", null: false
    t.uuid "sbom_id", null: false
    t.string "status", default: "draft", null: false
    t.text "summary"
    t.jsonb "target_vulnerabilities", default: [], null: false
    t.datetime "updated_at", null: false
    t.jsonb "upgrade_recommendations", default: [], null: false
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["approved_by_id"]
    t.index ["created_by_id"]
    t.index ["sbom_id"]
    t.check_constraint "plan_type::text = ANY (ARRAY['manual'::character varying::text, 'ai_generated'::character varying::text, 'auto_fix'::character varying::text])", name: "check_remediation_plans_type"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'pending_review'::character varying::text, 'approved'::character varying::text, 'rejected'::character varying::text, 'executing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "check_remediation_plans_status"
  end

  create_table "supply_chain_reports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.datetime "expires_at"
    t.string "file_path"
    t.bigint "file_size_bytes"
    t.string "file_url"
    t.string "format", default: "pdf", null: false
    t.datetime "generated_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.jsonb "parameters", default: {}, null: false
    t.string "report_type", null: false
    t.uuid "sbom_id"
    t.string "status", default: "pending", null: false
    t.jsonb "summary", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "report_type"]
    t.index ["account_id"]
    t.index ["created_at"]
    t.index ["created_by_id"]
    t.index ["sbom_id"]
    t.index ["status"]
    t.check_constraint "format::text = ANY (ARRAY['pdf'::character varying::text, 'json'::character varying::text, 'csv'::character varying::text, 'html'::character varying::text, 'xml'::character varying::text, 'spdx'::character varying::text, 'cyclonedx'::character varying::text])", name: "check_reports_format"
    t.check_constraint "report_type::text = ANY (ARRAY['sbom_export'::character varying::text, 'vulnerability'::character varying::text, 'vulnerability_report'::character varying::text, 'license_report'::character varying::text, 'attribution'::character varying::text, 'compliance'::character varying::text, 'compliance_summary'::character varying::text, 'vendor_risk'::character varying::text, 'vendor_assessment'::character varying::text, 'custom'::character varying::text])", name: "check_reports_type"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'generating'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'expired'::character varying::text])", name: "check_reports_status"
  end

  create_table "supply_chain_risk_assessments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "assessment_date"
    t.string "assessment_type", default: "initial", null: false
    t.uuid "assessor_id"
    t.datetime "completed_at"
    t.decimal "compliance_score", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.jsonb "evidence", default: [], null: false
    t.jsonb "findings", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.decimal "operational_score", precision: 5, scale: 2, default: "0.0"
    t.decimal "overall_score", precision: 5, scale: 2, default: "0.0"
    t.jsonb "recommendations", default: [], null: false
    t.decimal "security_score", precision: 5, scale: 2, default: "0.0"
    t.string "status", default: "in_progress", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.datetime "valid_until"
    t.uuid "vendor_id", null: false
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["assessment_type"]
    t.index ["assessor_id"]
    t.index ["vendor_id", "created_at"]
    t.index ["vendor_id"]
    t.check_constraint "assessment_type::text = ANY (ARRAY['initial'::character varying::text, 'periodic'::character varying::text, 'incident'::character varying::text, 'renewal'::character varying::text])", name: "check_risk_assessments_type"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'in_progress'::character varying::text, 'pending_review'::character varying::text, 'completed'::character varying::text, 'expired'::character varying::text])", name: "check_risk_assessments_status"
  end

  create_table "supply_chain_sbom_components", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "dependency_type", default: "direct", null: false
    t.integer "depth", default: 0, null: false
    t.string "ecosystem", null: false
    t.boolean "has_known_vulnerabilities", default: false, null: false
    t.boolean "is_outdated", default: false, null: false
    t.string "latest_version"
    t.string "license_compliance_status", default: "unknown"
    t.string "license_name"
    t.string "license_spdx_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "namespace"
    t.jsonb "properties", default: {}, null: false
    t.string "purl", null: false
    t.decimal "risk_score", precision: 5, scale: 2, default: "0.0"
    t.uuid "sbom_id", null: false
    t.string "scope"
    t.datetime "updated_at", null: false
    t.string "version"
    t.index ["account_id", "ecosystem"]
    t.index ["account_id"]
    t.index ["has_known_vulnerabilities"]
    t.index ["metadata"], name: "idx_sbom_components_metadata", using: :gin
    t.index ["purl"]
    t.index ["sbom_id", "purl"], unique: true
    t.index ["sbom_id"]
    t.check_constraint "dependency_type::text = ANY (ARRAY['direct'::character varying::text, 'transitive'::character varying::text, 'dev'::character varying::text, 'optional'::character varying::text, 'peer'::character varying::text])", name: "check_sbom_components_dependency_type"
    t.check_constraint "ecosystem::text = ANY (ARRAY['npm'::character varying::text, 'gem'::character varying::text, 'pip'::character varying::text, 'maven'::character varying::text, 'gradle'::character varying::text, 'go'::character varying::text, 'cargo'::character varying::text, 'nuget'::character varying::text, 'composer'::character varying::text, 'hex'::character varying::text, 'pub'::character varying::text, 'cocoapods'::character varying::text, 'swift'::character varying::text, 'other'::character varying::text])", name: "check_sbom_components_ecosystem"
  end

  create_table "supply_chain_sbom_diffs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "added_components", default: [], null: false
    t.integer "added_count", default: 0, null: false
    t.uuid "base_sbom_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "new_vulnerabilities", default: [], null: false
    t.jsonb "removed_components", default: [], null: false
    t.integer "removed_count", default: 0, null: false
    t.jsonb "resolved_vulnerabilities", default: [], null: false
    t.decimal "risk_delta", precision: 5, scale: 2, default: "0.0"
    t.uuid "target_sbom_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "updated_components", default: [], null: false
    t.integer "updated_count", default: 0, null: false
    t.index ["account_id", "created_at"]
    t.index ["account_id"]
    t.index ["base_sbom_id", "target_sbom_id"], unique: true
    t.index ["base_sbom_id"]
    t.index ["target_sbom_id"]
  end

  create_table "supply_chain_sbom_vulnerabilities", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "component_id", null: false
    t.jsonb "context_factors", default: {}, null: false
    t.decimal "contextual_score", precision: 4, scale: 2
    t.datetime "created_at", null: false
    t.decimal "cvss_score", precision: 4, scale: 2
    t.string "cvss_vector"
    t.integer "cvss_version"
    t.text "description"
    t.text "dismissal_reason"
    t.datetime "dismissed_at"
    t.uuid "dismissed_by_id"
    t.string "fixed_version"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "modified_at"
    t.datetime "published_at"
    t.jsonb "references", default: [], null: false
    t.string "remediation_status", default: "open", null: false
    t.uuid "sbom_id", null: false
    t.string "severity", default: "unknown", null: false
    t.string "source", default: "nvd", null: false
    t.datetime "updated_at", null: false
    t.string "vulnerability_id", null: false
    t.index ["account_id", "severity"]
    t.index ["account_id"]
    t.index ["component_id"]
    t.index ["context_factors"], name: "idx_sbom_vulns_context", using: :gin
    t.index ["dismissed_by_id"]
    t.index ["remediation_status"]
    t.index ["sbom_id", "vulnerability_id", "component_id"], unique: true
    t.index ["sbom_id"]
    t.index ["vulnerability_id"]
    t.check_constraint "remediation_status::text = ANY (ARRAY['open'::character varying::text, 'in_progress'::character varying::text, 'fixed'::character varying::text, 'dismissed'::character varying::text, 'wont_fix'::character varying::text])", name: "check_sbom_vulns_remediation_status"
    t.check_constraint "severity::text = ANY (ARRAY['critical'::character varying::text, 'high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text, 'none'::character varying::text, 'unknown'::character varying::text])", name: "check_sbom_vulns_severity"
  end

  create_table "supply_chain_sboms", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "branch"
    t.string "commit_sha"
    t.integer "component_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.jsonb "document", default: {}, null: false
    t.string "document_hash"
    t.string "format", default: "cyclonedx_1_5", null: false
    t.uuid "git_repository_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.boolean "ntia_minimum_compliant", default: false, null: false
    t.uuid "pipeline_run_id"
    t.decimal "risk_score", precision: 5, scale: 2, default: "0.0"
    t.string "sbom_id", null: false
    t.text "signature"
    t.string "signature_algorithm"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "version"
    t.integer "vulnerability_count", default: 0, null: false
    t.index ["account_id", "sbom_id"], unique: true
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["created_at"]
    t.index ["created_by_id"]
    t.index ["git_repository_id", "commit_sha"]
    t.index ["git_repository_id"]
    t.index ["metadata"], name: "idx_sboms_metadata", using: :gin
    t.index ["pipeline_run_id"]
    t.check_constraint "format::text = ANY (ARRAY['spdx_2_3'::character varying::text, 'cyclonedx_1_4'::character varying::text, 'cyclonedx_1_5'::character varying::text, 'cyclonedx_1_6'::character varying::text])", name: "check_sboms_format"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'generating'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'archived'::character varying::text])", name: "check_sboms_status"
  end

  create_table "supply_chain_scan_executions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "execution_id", null: false
    t.jsonb "input_data", default: {}, null: false
    t.text "logs"
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "output_data", default: {}, null: false
    t.uuid "scan_instance_id", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.string "trigger_type", default: "manual", null: false
    t.uuid "triggered_by_id"
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["execution_id"], unique: true
    t.index ["scan_instance_id", "created_at"]
    t.index ["scan_instance_id"]
    t.index ["triggered_by_id"]
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'running'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'cancelled'::character varying::text])", name: "check_scan_executions_status"
    t.check_constraint "trigger_type::text = ANY (ARRAY['manual'::character varying::text, 'scheduled'::character varying::text, 'webhook'::character varying::text, 'pipeline'::character varying::text, 'api'::character varying::text])", name: "check_scan_executions_trigger"
  end

  create_table "supply_chain_scan_instances", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "execution_count", default: 0, null: false
    t.integer "failure_count", default: 0, null: false
    t.uuid "installed_by_id"
    t.datetime "last_execution_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "next_execution_at"
    t.uuid "scan_template_id", null: false
    t.string "schedule_cron"
    t.string "status", default: "active", null: false
    t.integer "success_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "scan_template_id"], unique: true
    t.index ["account_id"]
    t.index ["installed_by_id"]
    t.index ["next_execution_at"]
    t.index ["scan_template_id"]
    t.index ["status"]
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'paused'::character varying::text, 'disabled'::character varying::text])", name: "check_scan_instances_status"
  end

  create_table "supply_chain_scan_templates", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.string "category", default: "security", null: false
    t.jsonb "configuration_schema", default: {}, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.jsonb "default_configuration", default: {}, null: false
    t.text "description"
    t.integer "install_count", default: 0, null: false
    t.boolean "is_public", default: false, null: false
    t.boolean "is_system", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.jsonb "supported_ecosystems", default: [], null: false
    t.datetime "updated_at", null: false
    t.string "version", default: "1.0.0", null: false
    t.index ["account_id"]
    t.index ["category"]
    t.index ["created_by_id"]
    t.index ["is_public"]
    t.index ["slug"], unique: true
    t.index ["status"]
    t.check_constraint "category::text = ANY (ARRAY['security'::character varying::text, 'compliance'::character varying::text, 'license'::character varying::text, 'quality'::character varying::text, 'custom'::character varying::text])", name: "check_scan_templates_category"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'published'::character varying::text, 'archived'::character varying::text, 'deprecated'::character varying::text])", name: "check_scan_templates_status"
  end

  create_table "supply_chain_signing_keys", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.text "encrypted_private_key"
    t.datetime "expires_at"
    t.string "fingerprint", null: false
    t.string "key_id", null: false
    t.string "key_type", default: "cosign", null: false
    t.string "kms_key_uri"
    t.string "kms_provider"
    t.string "kms_region"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.text "public_key", null: false
    t.datetime "rotated_at"
    t.uuid "rotated_from_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "key_id"], unique: true
    t.index ["account_id"]
    t.index ["created_by_id"]
    t.index ["fingerprint"], unique: true
    t.index ["rotated_from_id"]
    t.index ["status"]
    t.check_constraint "key_type::text = ANY (ARRAY['cosign'::character varying::text, 'oidc_identity'::character varying::text, 'kms_reference'::character varying::text, 'gpg'::character varying::text])", name: "check_signing_keys_type"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'rotating'::character varying::text, 'rotated'::character varying::text, 'revoked'::character varying::text, 'expired'::character varying::text])", name: "check_signing_keys_status"
  end

  create_table "supply_chain_vendor_monitoring_events", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "acknowledged_at"
    t.uuid "acknowledged_by_id"
    t.jsonb "affected_services", default: [], null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "detected_at", null: false
    t.string "event_type", null: false
    t.string "external_url"
    t.boolean "is_acknowledged", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "recommended_actions", default: [], null: false
    t.datetime "resolved_at"
    t.string "severity", default: "info", null: false
    t.string "source", default: "internal", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "vendor_id", null: false
    t.index ["account_id", "severity"]
    t.index ["account_id"]
    t.index ["acknowledged_by_id"]
    t.index ["event_type"]
    t.index ["is_acknowledged"]
    t.index ["vendor_id", "created_at"]
    t.index ["vendor_id"]
    t.check_constraint "event_type::text = ANY (ARRAY['security_incident'::character varying::text, 'breach'::character varying::text, 'certification_expiry'::character varying::text, 'contract_renewal'::character varying::text, 'service_degradation'::character varying::text, 'compliance_update'::character varying::text, 'news_alert'::character varying::text])", name: "check_vendor_events_type"
    t.check_constraint "severity::text = ANY (ARRAY['critical'::character varying::text, 'high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text, 'info'::character varying::text])", name: "check_vendor_events_severity"
  end

  create_table "supply_chain_vendors", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "certifications", default: [], null: false
    t.string "contact_email"
    t.datetime "contract_end_date"
    t.datetime "contract_start_date"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.boolean "handles_pci", default: false, null: false
    t.boolean "handles_phi", default: false, null: false
    t.boolean "handles_pii", default: false, null: false
    t.boolean "has_baa", default: false, null: false
    t.boolean "has_dpa", default: false, null: false
    t.datetime "last_assessment_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "next_assessment_due"
    t.decimal "risk_score", precision: 5, scale: 2, default: "0.0"
    t.string "risk_tier", default: "medium", null: false
    t.jsonb "security_contacts", default: [], null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.string "vendor_type", default: "saas", null: false
    t.string "website"
    t.index ["account_id", "slug"], unique: true
    t.index ["account_id"]
    t.index ["certifications"], name: "idx_vendors_certifications", using: :gin
    t.index ["created_by_id"]
    t.index ["risk_tier"]
    t.index ["status"]
    t.check_constraint "risk_tier::text = ANY (ARRAY['critical'::character varying::text, 'high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text])", name: "check_vendors_risk_tier"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text, 'under_review'::character varying::text, 'terminated'::character varying::text])", name: "check_vendors_status"
    t.check_constraint "vendor_type::text = ANY (ARRAY['saas'::character varying::text, 'api'::character varying::text, 'library'::character varying::text, 'infrastructure'::character varying::text, 'hardware'::character varying::text, 'consulting'::character varying::text, 'other'::character varying::text])", name: "check_vendors_type"
  end

  create_table "supply_chain_verification_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "attestation_id", null: false
    t.datetime "created_at", null: false
    t.string "log_hash", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "previous_log_hash"
    t.string "result", null: false
    t.text "result_message"
    t.datetime "updated_at", null: false
    t.jsonb "verification_details", default: {}, null: false
    t.string "verification_type", null: false
    t.uuid "verified_by_id"
    t.index ["account_id"]
    t.index ["attestation_id", "created_at"]
    t.index ["attestation_id"]
    t.index ["log_hash"], unique: true
    t.index ["previous_log_hash"]
    t.index ["verified_by_id"]
  end

  create_table "supply_chain_vulnerability_feeds", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "api_key_encrypted"
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "entry_count", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_sync_at"
    t.text "last_sync_error"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "source", null: false
    t.string "sync_status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["account_id", "source"], unique: true
    t.index ["account_id"]
    t.index ["sync_status"]
    t.check_constraint "source::text = ANY (ARRAY['nvd'::character varying::text, 'osv'::character varying::text, 'github_advisory'::character varying::text, 'snyk'::character varying::text, 'sonatype'::character varying::text, 'custom'::character varying::text])", name: "check_vuln_feeds_source"
    t.check_constraint "sync_status::text = ANY (ARRAY['pending'::character varying::text, 'syncing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "check_vuln_feeds_sync_status"
  end

  create_table "supply_chain_vulnerability_scans", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "completed_at"
    t.uuid "container_image_id", null: false
    t.datetime "created_at", null: false
    t.integer "critical_count", default: 0, null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.integer "high_count", default: 0, null: false
    t.jsonb "layer_vulnerabilities", default: {}, null: false
    t.integer "low_count", default: 0, null: false
    t.integer "medium_count", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "sbom", default: {}, null: false
    t.string "scanner_name", default: "trivy", null: false
    t.string "scanner_version"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.uuid "triggered_by_id"
    t.integer "unknown_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.jsonb "vulnerabilities", default: [], null: false
    t.index ["account_id", "status"]
    t.index ["account_id"]
    t.index ["container_image_id", "created_at"]
    t.index ["container_image_id"]
    t.index ["triggered_by_id"]
    t.index ["vulnerabilities"], name: "idx_vuln_scans_vulns", using: :gin
    t.check_constraint "scanner_name::text = ANY (ARRAY['trivy'::character varying::text, 'grype'::character varying::text, 'clair'::character varying::text, 'snyk'::character varying::text, 'custom'::character varying::text])", name: "check_vuln_scans_scanner"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'running'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'cancelled'::character varying::text])", name: "check_vuln_scans_status"
  end

    add_foreign_key "supply_chain_attestations", "accounts", column: "account_id"
    add_foreign_key "supply_chain_attestations", "devops_pipeline_runs", column: "pipeline_run_id"
    add_foreign_key "supply_chain_attestations", "supply_chain_sboms", column: "sbom_id"
    add_foreign_key "supply_chain_attestations", "supply_chain_signing_keys", column: "signing_key_id"
    add_foreign_key "supply_chain_attestations", "users", column: "created_by_id"
    add_foreign_key "supply_chain_attributions", "accounts", column: "account_id"
    add_foreign_key "supply_chain_attributions", "supply_chain_licenses", column: "license_id"
    add_foreign_key "supply_chain_attributions", "supply_chain_sbom_components", column: "sbom_component_id", on_delete: :cascade
    add_foreign_key "supply_chain_build_provenances", "accounts", column: "account_id"
    add_foreign_key "supply_chain_build_provenances", "supply_chain_attestations", column: "attestation_id", on_delete: :cascade
    add_foreign_key "supply_chain_container_images", "accounts", column: "account_id"
    add_foreign_key "supply_chain_container_images", "supply_chain_attestations", column: "attestation_id"
    add_foreign_key "supply_chain_container_images", "supply_chain_container_images", column: "base_image_id"
    add_foreign_key "supply_chain_container_images", "supply_chain_sboms", column: "sbom_id"
    add_foreign_key "supply_chain_cve_monitors", "accounts", column: "account_id"
    add_foreign_key "supply_chain_cve_monitors", "users", column: "created_by_id"
    add_foreign_key "supply_chain_image_policies", "accounts", column: "account_id"
    add_foreign_key "supply_chain_image_policies", "users", column: "created_by_id"
    add_foreign_key "supply_chain_license_detections", "accounts", column: "account_id"
    add_foreign_key "supply_chain_license_detections", "supply_chain_licenses", column: "license_id"
    add_foreign_key "supply_chain_license_detections", "supply_chain_sbom_components", column: "sbom_component_id", on_delete: :cascade
    add_foreign_key "supply_chain_license_policies", "accounts", column: "account_id"
    add_foreign_key "supply_chain_license_policies", "users", column: "created_by_id"
    add_foreign_key "supply_chain_license_violations", "accounts", column: "account_id"
    add_foreign_key "supply_chain_license_violations", "supply_chain_license_policies", column: "license_policy_id"
    add_foreign_key "supply_chain_license_violations", "supply_chain_licenses", column: "license_id"
    add_foreign_key "supply_chain_license_violations", "supply_chain_sbom_components", column: "sbom_component_id"
    add_foreign_key "supply_chain_license_violations", "supply_chain_sboms", column: "sbom_id"
    add_foreign_key "supply_chain_license_violations", "users", column: "exception_approved_by_id"
    add_foreign_key "supply_chain_questionnaire_responses", "accounts", column: "account_id"
    add_foreign_key "supply_chain_questionnaire_responses", "supply_chain_questionnaire_templates", column: "template_id"
    add_foreign_key "supply_chain_questionnaire_responses", "supply_chain_risk_assessments", column: "risk_assessment_id"
    add_foreign_key "supply_chain_questionnaire_responses", "supply_chain_vendors", column: "vendor_id"
    add_foreign_key "supply_chain_questionnaire_responses", "users", column: "requested_by_id"
    add_foreign_key "supply_chain_questionnaire_responses", "users", column: "reviewed_by_id"
    add_foreign_key "supply_chain_questionnaire_templates", "accounts", column: "account_id"
    add_foreign_key "supply_chain_questionnaire_templates", "users", column: "created_by_id"
    add_foreign_key "supply_chain_remediation_plans", "accounts", column: "account_id"
    add_foreign_key "supply_chain_remediation_plans", "supply_chain_sboms", column: "sbom_id"
    add_foreign_key "supply_chain_remediation_plans", "users", column: "approved_by_id"
    add_foreign_key "supply_chain_remediation_plans", "users", column: "created_by_id"
    add_foreign_key "supply_chain_reports", "accounts", column: "account_id"
    add_foreign_key "supply_chain_reports", "supply_chain_sboms", column: "sbom_id"
    add_foreign_key "supply_chain_reports", "users", column: "created_by_id"
    add_foreign_key "supply_chain_risk_assessments", "accounts", column: "account_id"
    add_foreign_key "supply_chain_risk_assessments", "supply_chain_vendors", column: "vendor_id", on_delete: :cascade
    add_foreign_key "supply_chain_risk_assessments", "users", column: "assessor_id"
    add_foreign_key "supply_chain_sbom_components", "accounts", column: "account_id"
    add_foreign_key "supply_chain_sbom_components", "supply_chain_sboms", column: "sbom_id", on_delete: :cascade
    add_foreign_key "supply_chain_sbom_diffs", "accounts", column: "account_id"
    add_foreign_key "supply_chain_sbom_diffs", "supply_chain_sboms", column: "base_sbom_id"
    add_foreign_key "supply_chain_sbom_diffs", "supply_chain_sboms", column: "target_sbom_id"
    add_foreign_key "supply_chain_sbom_vulnerabilities", "accounts", column: "account_id"
    add_foreign_key "supply_chain_sbom_vulnerabilities", "supply_chain_sbom_components", column: "component_id", on_delete: :cascade
    add_foreign_key "supply_chain_sbom_vulnerabilities", "supply_chain_sboms", column: "sbom_id", on_delete: :cascade
    add_foreign_key "supply_chain_sbom_vulnerabilities", "users", column: "dismissed_by_id"
    add_foreign_key "supply_chain_sboms", "accounts", column: "account_id"
    add_foreign_key "supply_chain_sboms", "devops_pipeline_runs", column: "pipeline_run_id"
    add_foreign_key "supply_chain_sboms", "git_repositories", column: "git_repository_id", on_delete: :nullify
    add_foreign_key "supply_chain_sboms", "users", column: "created_by_id"
    add_foreign_key "supply_chain_scan_executions", "accounts", column: "account_id"
    add_foreign_key "supply_chain_scan_executions", "supply_chain_scan_instances", column: "scan_instance_id", on_delete: :cascade
    add_foreign_key "supply_chain_scan_executions", "users", column: "triggered_by_id"
    add_foreign_key "supply_chain_scan_instances", "accounts", column: "account_id"
    add_foreign_key "supply_chain_scan_instances", "supply_chain_scan_templates", column: "scan_template_id"
    add_foreign_key "supply_chain_scan_instances", "users", column: "installed_by_id"
    add_foreign_key "supply_chain_scan_templates", "accounts", column: "account_id"
    add_foreign_key "supply_chain_scan_templates", "users", column: "created_by_id"
    add_foreign_key "supply_chain_signing_keys", "accounts", column: "account_id"
    add_foreign_key "supply_chain_signing_keys", "supply_chain_signing_keys", column: "rotated_from_id"
    add_foreign_key "supply_chain_signing_keys", "users", column: "created_by_id"
    add_foreign_key "supply_chain_vendor_monitoring_events", "accounts", column: "account_id"
    add_foreign_key "supply_chain_vendor_monitoring_events", "supply_chain_vendors", column: "vendor_id", on_delete: :cascade
    add_foreign_key "supply_chain_vendor_monitoring_events", "users", column: "acknowledged_by_id"
    add_foreign_key "supply_chain_vendors", "accounts", column: "account_id"
    add_foreign_key "supply_chain_vendors", "users", column: "created_by_id"
    add_foreign_key "supply_chain_verification_logs", "accounts", column: "account_id"
    add_foreign_key "supply_chain_verification_logs", "supply_chain_attestations", column: "attestation_id"
    add_foreign_key "supply_chain_verification_logs", "users", column: "verified_by_id"
    add_foreign_key "supply_chain_vulnerability_feeds", "accounts", column: "account_id"
    add_foreign_key "supply_chain_vulnerability_scans", "accounts", column: "account_id"
    add_foreign_key "supply_chain_vulnerability_scans", "supply_chain_container_images", column: "container_image_id", on_delete: :cascade
    add_foreign_key "supply_chain_vulnerability_scans", "users", column: "triggered_by_id"
  end
end
