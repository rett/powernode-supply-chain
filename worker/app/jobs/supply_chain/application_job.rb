# frozen_string_literal: true

module SupplyChain
  class ApplicationJob < ::BaseJob
    # Base class for all supply chain extension jobs.
    # Inherits from the worker's BaseJob which provides
    # API client, error handling, and retry logic.
  end
end
