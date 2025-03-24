# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module ActiveRecordRescues
        RESCUE_ERRORS = [
          ActiveRecord::RecordInvalid,
          ActiveRecord::RecordNotFound,
          ActiveRecord::RecordNotUnique
        ].freeze

        def with_broadcast(args)
          super
        rescue *RESCUE_ERRORS => e
          error = adapter.options[:message] || e
          Failure(
            Dry::Transaction::StepFailure.call(self, error) do
              publish(:step_failed, step_name: name, args: args, value: error)
            end
          )
        end
      end
    end
  end
end
