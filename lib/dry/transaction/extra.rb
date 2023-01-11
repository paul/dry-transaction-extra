# frozen_string_literal: true

require_relative "extra/version"

require "dry/monads"
require "dry/transaction"

require_relative "extra/steps/tap"
require_relative "extra/steps/merge"

module Dry
  module Transaction
    module Extra
      def self.maybe_register(key, impl)
        Dry::Transaction::StepAdapters.register(key, impl) unless Dry::Transaction::StepAdapters.key?(key)
      end

      maybe_register(:merge, Extra::Steps::Merge.new)
      maybe_register(:tap, Extra::Steps::Tap.new)
    end
  end
end
