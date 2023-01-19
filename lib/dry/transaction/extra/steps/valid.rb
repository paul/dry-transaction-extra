# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        # Runs a dry-schema or dry-validation Contract, either passed to the
        # step directly, or returned from the step method. It runs the
        # validator on the input arguments, and returns Success on the
        # validator output, or the Failure with errors returned from the
        # validator.
        #
        # @example Validator defined in step implementation
        #
        # valid :validate_params
        #
        # def validate_params(params)
        #   Dry::Schema.Params do
        #     required(:name).filled(:string)
        #     required(:email).filled(:string)
        #   end
        # end
        #
        # This is essentially equivalent to:
        #
        # step :validate_params
        #
        # def validate_params(params)
        #   Dry::Schema.Params do
        #     required(:name).filled(:string)
        #     required(:email).filled(:string)
        #   end.call(params).to_monad
        # end
        #
        #
        # @example Validator provided to the step
        #
        # valid ParamsValidator
        #
        class Valid
          include Dry::Monads[:result]
          def call(operation, _options, args)
            if args.size > 1 || (!args[0].is_a?(Hash) && !args[0].nil?)
              raise ArgumentError,
                    "the valid step only works with hash/keyword arguments"
            end

            # The operation is a callable that returns a schema/contract, which
            # itself needs to be called
            result = operation.call.call(args[0])
            if result.success?
              Success(result.to_h)
            else
              Failure(result)
            end
          end

          module DSL
            def valid(validator, name: nil)
              return super(validator) if validator.is_a?(Symbol)

              method_name = (name || validator.inspect || "validate").to_sym
              define_method method_name do |**|
                validator
              end

              super(method_name)
            end
          end
        end
      end
    end
  end
end
