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

### `tap` 

A step that mimics Ruby's builtin [Kernel#tap](https://ruby-doc.org/3.1.2/Kernel.html#method-i-tap) method. If the step succeeds, the step output is ignored and the original input is returned. However, if the step fails, then that Failure is returned instead.

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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/paul/dry-transaction-extra. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/paul/dry-transaction-extra/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dry::Transaction::Extra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/paul/dry-transaction-extra/blob/main/CODE_OF_CONDUCT.md).
