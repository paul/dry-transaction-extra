# frozen_string_literal: true

require_relative "extra/version"

require "dry/monads"
require "dry/transaction"

require_relative "extra/steps/tap"

module Dry
  module Transaction
    module Extra
      def self.maybe_register(key, impl)
        Dry::Transaction::StepAdapters.register(key, impl) unless Dry::Transaction::StepAdapters.key?(key)
      end

      maybe_register(:tap, Extra::Steps::Tap.new)
    end
  end
end
