# frozen_string_literal: true

require_relative "lib/dry/transaction/extra/version"

Gem::Specification.new do |spec|
  spec.name = "dry-transaction-extra"
  spec.version = Dry::Transaction::Extra::VERSION
  spec.authors = ["Paul Sadauskas"]
  spec.email = ["psadauskas@gmail.com"]

  spec.summary = "Extra steps and functionality for Dry::Transaction"
  spec.description = "Dry::Transaction comes with a limited set of steps. This \
  gem defines a few more steps that are useful for getting the most out of Transactions."
  spec.homepage = "https://github.com/paul/dry-transaction-extra"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/paul/dry-transaction-extra"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-monads", "~> 1.3"
  spec.add_dependency "dry-transaction", "~> 0.15"

  spec.add_development_dependency "dry-container", "~> 0.7"
  spec.add_development_dependency "dry-schema", "~> 1.10"
  spec.add_development_dependency "dry-validation", "~> 1.8"
end
