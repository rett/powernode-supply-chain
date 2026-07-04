# frozen_string_literal: true

require "rails_helper"

# Regression guard for the audit-action registration drift class: every
# supply_chain.* token actually emitted via log_audit_event(...) in this
# extension's controllers must be present in the "supply_chain" namespace
# registered with AuditActions (lib/powernode_supply_chain/engine.rb). The
# registered list is hand-maintained and can drift from what's actually
# emitted — found + fixed by this change: supply_chain.sboms.rescan was
# emitted by SbomsController#rescan but missing from the registered set,
# which would have raised ActiveRecord::RecordInvalid on every rescan (the
# systemic bug class this seam exists to prevent). This spec scans the
# controller sources directly so it never needs updating by hand when a new
# log_audit_event call is added — the call site just has to stay registered.
RSpec.describe "PowernodeSupplyChain audit actions registration", type: :lib do
  let(:controllers_root) { Rails.root.join("../extensions/supply-chain/server/app/controllers") }

  let(:emitted_actions) do
    Dir.glob(controllers_root.join("**/*.rb")).flat_map do |path|
      File.read(path).scan(/log_audit_event\(\s*["'](supply_chain\.[a-z_.]+)["']/).flatten
    end.uniq.sort
  end

  it "found emitted supply_chain.* actions to check (sanity check the scan itself)" do
    expect(emitted_actions).not_to be_empty
  end

  it "registers and validates every action actually emitted via log_audit_event" do
    emitted_actions.each do |action|
      expect(AuditActions.valid_action?(action)).to be(true),
        "#{action} is emitted by a controller but not registered — " \
        "add it to the supply_chain_actions list in engine.rb"
    end
  end
end
