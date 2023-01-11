# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        # A step that mimics Ruby's builtin
        # [Kernel#tap](https://ruby-doc.org/3.1.2/Kernel.html#method-i-tap)
        # method. If the step succeeds, the step output is ignored and the
        # original input is returned. However, if the step fails, then that
        # Failure is returned instead.
        #
        # @example
        #
        #   tap :track_user
        #   map :next_step
        #
        #   def track_user(user)
        #     response = Tracker.track(user_id: user.email)
        #     return Failure(response.body) if response.status >= 400
        #   end
        #
        #   def next_step(user)
        #     # Normally, the return value if the previous step would be passed
        #     # as the input to this step. In this case, we don't care, we want
        #     # to keep going with the original input `user`.
        #   end
        class Tap
          include Dry::Monads[:result]

          def call(operation, _options, args)
            result = operation.call(*args)
            return result if result.is_a?(Failure)

            Success(*args)
          end
        end
      end
    end
  end
end
