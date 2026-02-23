# frozen_string_literal: true

module SupplyChain
  class ApplicationJob < ::BaseJob
    # Bridge ActiveJob's queue_as to Sidekiq's sidekiq_options.
    # Supply chain jobs use `queue_as :name` (ActiveJob pattern)
    # but the worker uses raw Sidekiq via BaseJob.
    def self.queue_as(queue_name)
      sidekiq_options queue: queue_name.to_s
    end
  end
end
