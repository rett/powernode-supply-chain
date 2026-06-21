# frozen_string_literal: true

# Supply-chain extension seed orchestrator (formal contract — explicit list, no
# glob). Invoked by the parent platform's db/seeds.rb extension loop, which runs
# AFTER core seeds (so the shared KB categories created by core's
# knowledge_base_articles.rb already exist when kb/*.rb does find_by!(category)).
# Order: data templates first, then KB articles.
ext_seeds = File.expand_path("seeds", __dir__)

SUPPLY_CHAIN_SEED_FILES = %w[
  supply_chain_licenses.rb
  supply_chain_scan_templates.rb
  supply_chain_questionnaire_templates.rb
  kb/supply_chain_articles.rb
].freeze

SUPPLY_CHAIN_SEED_FILES.each do |seed_file|
  path = File.join(ext_seeds, seed_file)
  next unless File.exist?(path)

  begin
    load path
  rescue StandardError => e
    Rails.logger.error("[supply-chain seeds] #{seed_file} failed: #{e.class}: #{e.message}")
    puts "  ❌ #{seed_file} failed: #{e.message}"
  end
end
