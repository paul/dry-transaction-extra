# frozen_string_literal: true

require_relative "extra/version"

require "dry/monads"
require "dry/transaction"

require_relative "extra/steps/tap"
require_relative "extra/steps/merge"
require_relative "extra/steps/valid"

require_relative "extra/validation_dsl"

module Dry
  module Transaction
    module Extra
      def self.included(klass)
        klass.extend Extra::Steps::Valid::DSL
        klass.extend Dry::Core::Extensions

        klass.register_extension :validation do
          klass.extend ValidationDSL
        end
      end

      {
        merge: Extra::Steps::Merge.new,
        tap: Extra::Steps::Tap.new,
        valid: Extra::Steps::Valid.new
      }.each do |key, impl|
        Dry::Transaction::StepAdapters.register(key, impl) unless Dry::Transaction::StepAdapters.key?(key)
      end
    end
  end
end
