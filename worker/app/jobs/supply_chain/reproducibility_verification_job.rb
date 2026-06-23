# frozen_string_literal: true

module SupplyChain
  # Thin HTTP shim: delegates reproducibility verification to the server, which
  # loads the BuildProvenance + User, runs the pure-Ruby verification, marks the
  # result, and (optionally) notifies the user (all ActiveRecord + ActionCable).
  # The worker is API-only and holds no models.
  #
  # +provenance_id+ is a BuildProvenance id (the dispatcher passes @provenance.id);
  # +user_id+ is the user to notify on completion.
  class ReproducibilityVerificationJob < ApplicationJob
    queue_as :default

    sidekiq_options retry: 3

    def execute(provenance_id, user_id)
      response = api_client.post(
        "/api/v1/internal/supply_chain/build_provenance/#{provenance_id}/verify",
        { user_id: user_id }
      )
      response.is_a?(Hash) ? (response["data"] || {}) : {}
    end
  end
end
