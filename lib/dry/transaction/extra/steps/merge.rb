# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        # If you're using keyword args as the arguments to your steps, you
        # often want a step to add its output to those args, while keeping the
        # original kwargs intact.
        #
        #  * If the output of the step is a Hash, then that hash is merged into the input.
        #  * If the output of the step is not a Hash, then a key is inferred
        #    from the step name. The name of the key can be overridden with the
        #    `as:` option.
        #
        # @option as [Symbol] When merging the output, use this as the key
        #
        # @example Merging Hash output
        #
        #   merge :add_context
        #
        #   # Input: { user: #<User id:42>, account: #<Account id:1> }
        #   def add_context(user:, **)
        #     {
        #       email: user.email,
        #       token: UserToken.lookup(user)
        #     }
        #   end
        #   # Output: { user: #<User id:42>, account: #<Account id:1>, email: "paul@myapp.example", token: "1234" }
        #
        # @example Merging non-Hash output, inferring the key from the step name
        #
        #   merge :user
        #
        #   # Input: { id: 42 }
        #   def user(id:, **)
        #     User.find(id)
        #   end
        #   # Output: { id: 42, user: #<User id:42> }
        #
        # @example Merging non-Hash output, specifying the key explicitly
        #
        #   merge :find_user, as: :current_user
        #
        #   # Input: { id: 42 }
        #   def find_user(id:, **)
        #     User.find(id)
        #   end
        #   # Output: { id: 42, current_user: #<User id:42> }
        #
        class Merge
          include Dry::Monads[:result]

          def call(operation, options, args)
            if args.size > 1 || (!args[0].is_a?(Hash) && !args[0].nil?)
              raise ArgumentError,
                    "the merge step only works with keyword arguments"
            end

            result = operation.call(*args)
            return result if result.is_a?(Failure)

            value = result.is_a?(Success) ? result.value! : result
            unless value.is_a?(Hash)
              key = options[:as] || options[:step_name]
              value = { key.to_sym => value }
            end

            Success((args[0] || {}).merge(value))
          end
        end
      end
    end
  end
end
