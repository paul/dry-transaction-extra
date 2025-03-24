# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        # Executes the step in a background job. Argument is an ActiveJob or anything that
        # implements `#perform_later`. This can include other Transactions when using the
        # :perform_later extension.
        #
        # If the provided transaction implements a `validate` step, then that validator will be
        # called on the input before the job is enqueued. This prevents us from enqueuing jobs with
        # garbage arguemnts that can never be run, and limits the params passed through the message
        # body into only those relevant to the job.
        #
        # Additionally, ActiveJob only allows for the serialization of a few types of values into
        # the message, Strings, Numbers and ActiveRecord::Model instances (via globalid). Anything
        # else will raise an ActiveJob::SerializationError.  Calling the validator beforehand helps
        # strip those out as well.
        #
        # Accepts an optional argument of delay:, to allow for jobs to be performed later, instead
        # of as soon as possible.
        #
        # Usage:
        #
        # async GuestsCleanupJob              # A job
        # async Guests::CleanStale            # A transaction
        # async DoThisLater, delay: 5.minutes # Optional delay for the job
        #
        module Async
          module DSL
            def async(job, delay: nil)
              method_name = job.name.underscore.intern
              step method_name
              define_method method_name do |input = {}|
                job = job.set(wait: delay) if delay

                if (validator = job&.validator)
                  result = validator.new.call(input)
                  # If the validator failed, don't enqueue the job, but don't
                  # also fail the step
                  job.perform_later(**result.to_h) if result.success?
                else
                  job.perform_later(**input)
                end

                Success(input)
              end
            end
          end
        end
      end
    end
  end
end
