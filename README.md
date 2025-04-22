# Dry::Transaction::Extra

Dry::Transaction comes with a limited set of steps. This gem defines a few more steps that are useful for getting the most out of Transactions.

## Installation


Install the gem and add to the application's Gemfile by executing:

    $ bundle add dry-transaction-extra

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install dry-transaction-extra

## Usage

By requiring the gem, you get a few additional Step adapters registered with dry-transaction, and can begin using them immediately. 

```ruby
require "dry-transaction-extra"
```

### Additional Steps

Dry::Transaction::Extra defines a few extra steps you can use:

 * [merge](#merge) -- Merges the output of the step with the input args. Best
   used with keyword arguments.
 * [tap](#tap) -- Similar to Ruby `Kernel#tap`, discards the return value of the step
   and returns the original input. If the step fails, then returns the Failure
   instead.
 * [valid](#valid) -- Runs a Dry::Schema or Dry::Validation::Contract on the
   input, and transforms the validation Result to a Result monad.
 * [use](#use) -- Invokes another transaction (or any other callable), and
   merges the result.
 * [maybe](#maybe) -- Optionally invokes another transaction by first
   attempting to invoke the validator. If the validation fails, it continues to
   the next step without failing.

#### `merge`

If you're using keyword args as the arguments to your steps, you often want a
step to add its output to those args, while keeping the original kwargs intact.

 * If the output of the step is a Hash, then that hash is merged into the input.
 * If the output of the step is not a Hash, then a key is inferred from the
   step name. The name of the key can be overridden with the `as:` option.

##### Merging Hash output

```ruby
merge :add_context

# Input: { user: #<User id:42>, account: #<Account id:1> }
def add_context(user:, **)
  {
    email: user.email,
    token: UserToken.lookup(user)
  }
end
# Output: { user: #<User id:42>, account: #<Account id:1>, email: "paul@myapp.example", token: "1234" }
```

##### Merging non-Hash output, inferring the key from the step name

```ruby
merge :user

# Input: { id: 42 }
def user(id:, **)
  User.find(id)
end
# Output: { id: 42, user: #<User id:42> }
```

##### Merging non-Hash output, specifying the key explicitly

```ruby
merge :find_user, as: :current_user

# Input: { id: 42 }
def find_user(id:, **)
  User.find(id)
end
# Output: { id: 42, current_user: #<User id:42> }
```

#### `tap` 

A step that mimics Ruby's builtin
[Kernel#tap](https://ruby-doc.org/3.1.2/Kernel.html#method-i-tap) method. If
the step succeeds, the step output is ignored and the original input is
returned. However, if the step fails, then that Failure is returned instead.

```ruby
tap :track_user
map :next_step

def track_user(user)
  response = Tracker.track(user_id: user.email)
  return Failure(response.body) if response.status >= 400
end

def next_step(user)
  # Normally, the return value if the previous step would be passed
  # as the input to this step. In this case, we don't care, we want
  # to keep going with the original input `user`.
end
```

#### `use`

Invokes another Transaction (or anything else `#call`-able), and merges the
result. It can also lookup the item to invoke in a container, which allows it
to be changed at runtime, or for tests.

The output of the invoked item is merged with the input, following the same
rules as the [`merge`][#merge] step.

This also works well in conjunction with the [Class Callable][#class-callable]
extension.

```ruby
use FindUser
use AppContainer, :find_user
use ->(id:, **) { User.find(id) }, as: "user"
use LoadBillingProfile, build_input: :billing_profile_input
```

You can optionally specify a `build_input:` method to prepare the input passed
to the nested transaction, allowing for better separation of concerns. This is
useful when the nested transaction expects a different shape than the current input.

```ruby
def billing_profile_input(user:, cart:, **)
  { customer_id: user.billing_id, currency: cart.currency }
end
```

This ensures that `LoadBillingProfile` receives only the relevant data, even
if the outer transaction includes broader context.

*Note*: The Container-lookup form of this is functionally equivalent to the built-in Dry Container Dependency Inject that is a part of Dry-Transaction (but lacking the `merge` semantics. However, you may find this method to be more readable, particularly when combined with other step adapters with a similar structure.

```ruby
class CreateUser
  step :validate, with: "validate"
  step :create, with: "create"

  # vs

  use UserContainer, "validate"
  use UserContainer, "create"
end
```

#### `valid`

Runs a Dry::Schema or Dry::Validation::Contract, either passed to the step
directly, or returned from the step method. It runs the validator on the input
arguments, and returns Success on the validator output, or the Failure with
errors returned from the validator.

```ruby
valid :validate_params

def validate_params(params)
  Dry::Schema.Params do
    required(:name).filled(:string)
    required(:email).filled(:string)
  end
end
```

*This is essentially equivalent to:*

```
step :validate_params

def validate_params(params)
  Dry::Schema.Params do
    required(:name).filled(:string)
    required(:email).filled(:string)
  end.call(params).to_monad
end
```

You can also define the Schema/Contract elsewhere if you want to reuse it, and invoke it:

```
valid ParamsValidator
```

#### `maybe`

Maybe combines the [`use`]( #use ) step with the [Validation
extension]( #validation ). Before attempting to run the provided transaction, it
first runs its defined validator. If that validation passes, then it invokes
the transaction. If the validation fails, however, then the transaction
continues on, silently ignoring the failure. This is useful in several
scenarios, like not running if there's insufficient data, or they've already
been run.

For example, when creating a user, if they provided an email address, we want
to send a verification email. If they didn't provide an email, or we've already
verified it, then we can skip that part. Given a `VerifyEmail` transaction with
a `validation` block that requires an email address, and does something to
check if we've already verified it, we can use a `maybe` to invoke it. If that
validator fails, then we can ignore it and create the user anyway. 

```ruby
class VerifyEmail
  include Dry::Transaction
  include Dry::Transaction::Extra
  load_extensions :validation, :class_callable

  validate do
    params do 
      required(:email).filled(type?: EmailAddress)
    end

    rule(:email) do
      !EmailValidation.exists?(value)
    end
  end

  step :send_verification_email
end

class CreateUser
  include Dry::Transaction
  include Dry::Transaction::Extra
  load_extensions :validation

  validate do
    params do 
      optional(:email).filled(:string)
    end
  end

  maybe VerifyEmail
  step :create_user
```


### Extensions

#### Validation

In addition to the [valid]( #valid ) step adapter, Dry::Transaction::Extra has
support for an explicit "pre-flight" validation that runs as the first step. 

```ruby
class CreateUser
  include Dry::Transaction
  include Dry::Transaction::Extra
  load_extensions :validation

  validate do
    params do
      required(:name).filled(:string)
      optional(:email).maybe(:string)
    end
  end

  step :create_user
end
```

This is useful if you want to, for example, run the transaction as an async background job, but want to first verify the arguments to the job before enqueueing it. If the job is going to fail anyway, why bother creating it in the first place?

```ruby
result = CreateUser.validator.new.call(params)
CreateUserJob.perform_async(params) unless result.failure?
```

#### Class Callable

This is a nice shorthand to initialize and call a Transaction in a single method. If you don't need to pass any arguments to the initializer, then you can `#call` it directly on the class:

```ruby
MyTransaction.new.call(args)
MyTransaction.call(args)
```

This is particularly useful when invoking transactions via the [`use`]( #use ) and [`maybe`]( #maybe ) steps:

```
use   MyTransaction
maybe MyOptionalTransaction
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/paul/dry-transaction-extra. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/paul/dry-transaction-extra/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dry::Transaction::Extra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/paul/dry-transaction-extra/blob/main/CODE_OF_CONDUCT.md).
