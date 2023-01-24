# frozen_string_literal: true

require_relative "extra/version"

require "dry/monads"
require "dry/transaction"

require_relative "extra/steps/tap"
require_relative "extra/steps/maybe"
require_relative "extra/steps/merge"
require_relative "extra/steps/use"
require_relative "extra/steps/valid"

require_relative "extra/class_callable"
require_relative "extra/validation_dsl"

module Dry
  module Transaction
    module Extra
      def self.included(klass)
        klass.extend Extra::Steps::Maybe::DSL
        klass.extend Extra::Steps::Use::DSL
        klass.extend Extra::Steps::Valid::DSL

        klass.extend Dry::Core::Extensions

        klass.register_extension :validation do
          klass.extend ValidationDSL
        end

        klass.register_extension :class_callable do
          klass.extend ClassCallable
        end
      end

      adapters = Dry::Transaction::StepAdapters
      {
        merge: Extra::Steps::Merge.new,
        tap: Extra::Steps::Tap.new,
        valid: Extra::Steps::Valid.new
      }.each do |key, impl|
        adapters.register(key, impl) unless adapters.key?(key)
      end
    end
  end
end
