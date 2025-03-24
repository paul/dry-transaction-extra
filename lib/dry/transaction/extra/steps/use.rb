# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      module Steps
        module Use
          module DSL
            # Invokes another transaction, or anything else #callable. Result
            # is merged, according to the same rules as the +merge+ step.
            #
            # Alternatively accepts a Contaner, and a key registered within
            # that container. This allows you to declare the transaction to be
            # used at runtime, instead of file load time.
            #
            # Note that this is basically equivalent to injecting the step into
            # the initializer, or passing in a container. However, using this
            # method may result in more readable code, and less surprise. See
            # README for a more detailed discussion.
            #
            # @param txn_or_container [#call, Dry::Container] A callable, or a Container
            # @param key [Symbol] If provided a Container, use this key for lookup
            #
            # @option as [Symbol] When merging the output, use this as the key
            #
            # @example
            #
            # use FindUser.new
            # use FindUser     # When using :class_callable extension
            #
            # @example Find transaction in Container
            #
            # use UserContainer, :find
            #
            # @example Merging output using specified key
            #
            # use FindUser, as: "user"
            #
            # # => { user: #<User: id=1> }
            #
            def use(txn_or_container, key = nil, as: nil, **)
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
