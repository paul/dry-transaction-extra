# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module PerformLater
        def self.extended(klass)
          klass.extend Dry::Core::ClassAttributes

          klass.defines :transaction_job
        end

        include Dry::Monads::Result::Mixin

        def set(options = {})
          ConfiguredJob.new(transaction_job, self, options)
        end

        def perform_later(*args)
          if validator
            result = validator.new.call(*args).to_monad
            return result unless result.success?

            args = [result.value!.to_h]
          end

          Dry::Monads::Success(transaction_job.new(transaction_class_name: name, args:).enqueue)
        end

        class ConfiguredJob
          def initialize(job_class, transaction, options = {})
            @job_class = job_class
            @transaction = transaction
            @options = options
          end

          def perform_later(*args)
            if validator
              result = validator.new.call(*args).to_monad
              return result unless result.success?

              args = [result.value!.to_h]
            end

            Dry::Monads::Success(
              transaction_job.new(transaction_class_name: @transaction.name, args:)
                .enqueue(@options)
            )
          end

          def validator
            @transaction.validator
          end
        end
      end
    end
  end
end
