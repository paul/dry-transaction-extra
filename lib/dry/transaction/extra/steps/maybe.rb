# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        module Maybe
          module DSL
            class NoValidatorError < ArgumentError
              def initialize(txn)
                super("The object provided to the step (#{txn}) does not implement a `validator` method.")
              end
            end

            # Just like the `use` step, this invokes another transaction. However, it first checks
            # to see if the transaction implements a `validator` method (usually provided by the
            # validation_dsl extension), and if so, will call it before invoking the transaction.
            #
            # If the validation succeeds, then it invokes the transaction as normal. If it fails, it
            # continues on with the next step, passing the original input through.
            #
            # @example
            #
            # step :create_user
            # maybe VerifyEmail
            #
            def maybe(txn_or_container, key = nil, as: nil, **)
              if key
                container = txn_or_container
                method_name = as || :"#{container.name}.#{key}"
              else
                txn = txn_or_container
                method_name = as || txn.name.to_sym
              end

              merge(method_name, as:, **)
              define_method method_name do |*args|
                txn = container[key] if key
                txn_class = txn.is_a?(Class) ? txn : txn.class
                raise NoValidatorError, txn unless txn_class.respond_to? :validator

                result = txn_class.validator.new.call(*args)
                if result.failure?
                  # publish(:maybe_failed, step_name: method_name, args:, value: result)
                  Rails.logger.debug "Skipping #{txn} because of errors: #{result.errors.to_h}" if defined?(Rails)
                  return Success(*args)
                end

                txn.call(*args)
              end
            rescue NoMethodError => e
              raise e unless e.name == :name

              raise ArgumentError, "unable to determine step name from #{key_or_container}.\
                  Pass an explicit step name using `as:` keyword argument."
            end
          end
        end
      end
    end
  end
end
