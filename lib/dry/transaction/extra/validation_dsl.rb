# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module ValidationDSL
        def self.extended(klass)
          klass.extend Dry::Core::ClassAttributes
          # The Dry::Validation Contract to run as the first step in the
          # Transaction. This exposes it publicly, so you can run it outside
          # the context of the Transction. This is useful if, for example, you
          # want to run the transaction in a job, but want to check if the
          # arguments are valid before enqueueing the job.
          #
          # @example
          #
          # class MyTransaction
          #   validate do
          #     params do
          #       required(:name).filled(:string)
          #     end
          #   end
          # end
          #
          # MyTransaction.validator.new.call(name: "Jane")
          # # => #<Dry::Validation::Result{name: "Jane"} errors={}>
          klass.defines :validator

          # Allows overriding the default validation contract class. This is useful if you want to
          # use a different Contract class with a different configuration.
          #
          # @example
          #
          # module MyApp
          #   module Types
          #     include Dry.Types()
          #
          #     Container = Dry::Schema::TypeContainer.new
          #     Container.register("params.email", String.constrained(format: /@/))
          #   end
          #
          #   class Contract < Dry::Validation::Contract
          #     config.types = Types::Container
          #   end
          # end
          #
          # module ApplicationTransaction
          #   include Dry::Transaction
          #   include Dry::Transaction::Extra
          #
          #   load_extensions :validation
          #
          #   validation_contract_class MyApp::Contract
          # end
          #
          # class MyTransaction
          #   include ApplicationTransaction
          #
          #   validate do
          #     params do
          #       # Now the custom `:email` type is available in this schema
          #       required(:email).filled(:email)
          #     end
          #   end
          # end
          klass.defines :validation_contract_class

          require "dry/validation"
          Dry::Validation.load_extensions(:monads)
        end

        # Allows you to declare a class-level validator, and run it as the
        # first step of the Transaction.
        #
        # @example Define the validation inline
        #
        # class CreateUser
        #   include Dry::Transaction
        #   include Dry::Transaction::Extra
        #   load_extensions :validation
        #
        #   validate do
        #     params do
        #       required(:name).filled(:string)
        #       optional(:email).maybe(:string)
        #     end
        #   end
        # end
        #
        # @example Reference a Validation defined elsewhere
        #
        # class NewUserContract < Dry::Validation::Contract
        #   params do
        #     required(:name).filled(:string)
        #     optional(:email).maybe(:string)
        #   end
        # end
        #
        # class CreateUser
        #   include Dry::Transaction
        #   include Dry::Transaction::Extra
        #   load_extensions :validation
        #
        #   validate NewUserContract
        # end
        #
        def validate(contract = nil, &)
          validator(contract || Class.new(validation_contract_class || Dry::Validation::Contract, &))

          valid(validator.new, name: "validate")
        end
      end
    end
  end
end
