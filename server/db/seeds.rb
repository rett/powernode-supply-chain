# frozen_string_literal: true

# Supply-chain extension seed orchestrator (formal contract — explicit lists, no
# glob). Invoked by the parent platform's db/seeds.rb extension loop, AFTER core
# seeds (so shared KB categories exist for kb/*.rb). CORE = account-independent
# reference data (always). DEMO = account-scoped KB articles (need an admin
# author), gated by Powernode::Seeds.demo? (POWERNODE_SEED_DEMO / dev-test).
ext_seeds = File.expand_path("seeds", __dir__)
seed_demo = !defined?(Powernode::Seeds) || Powernode::Seeds.demo?

load_seed = lambda do |seed_file|
  path = File.join(ext_seeds, seed_file)
  next unless File.exist?(path)

  begin
    load path
  rescue StandardError => e
    Rails.logger.error("[supply-chain seeds] #{seed_file} failed: #{e.class}: #{e.message}")
    puts "  ❌ #{seed_file} failed: #{e.message}"
  end
end

CORE_SEED_FILES = %w[
  supply_chain_licenses.rb
  supply_chain_scan_templates.rb
  supply_chain_questionnaire_templates.rb
].freeze

DEMO_SEED_FILES = %w[
  kb/supply_chain_articles.rb
].freeze

CORE_SEED_FILES.each(&load_seed)
DEMO_SEED_FILES.each(&load_seed) if seed_demo
