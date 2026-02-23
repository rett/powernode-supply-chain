# frozen_string_literal: true

module SupplyChain
  class ApplicationJob < ::BaseJob
    # Bridge ActiveJob class methods to Sidekiq equivalents.
    # Supply chain jobs were written with ActiveJob patterns (queue_as, retry_on)
    # but the worker uses raw Sidekiq via BaseJob.

    def self.queue_as(queue_name)
      sidekiq_options queue: queue_name.to_s
    end

    def self.retry_on(_exception, wait: nil, attempts: 3, **_options)
      sidekiq_options retry: attempts
    end

    def self.discard_on(*_exceptions)
      # Sidekiq handles this via dead letter queue — no direct equivalent needed
    end
  end
end
