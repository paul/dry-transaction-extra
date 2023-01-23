# frozen_string_literal: true

module Dry
  module Transaction
    module Extra
      # Creates a class-level call method, which creates a new instance and
      # invokes #call on it, delegating all arguments.
      #
      # These are equivalent:
      #
      #     MyTransaction.new.call(id: 1234)
      #     MyTransaction.call(id: 1234)
      #
      # Note that if you need to pass arguments to the initializer, you can't
      # use this, but if you don't, then this is a nice shortcut.
      #
      module ClassCallable
        def call(...)
          new.call(...)
        end
      end
    end
  end
end
