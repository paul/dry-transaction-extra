# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Extra Steps" do
  include_context "container"
  include Dry::Monads[:result]

  let(:dependencies) { {} }

  describe "tap" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)
        tap :track_user
      end.new(**dependencies)
    end

    let(:input) { { name: "Jane", email: "jane@doe.com" } }
    subject(:result) { transaction.call(input) }

    context "on success" do
      let(:track_user) { ->(name:, email:) { "tracked!" } }
      let(:dependencies) { { track_user: track_user } }

      it "returns the input" do
        expect(result).to eql(Success(input))
      end
    end

    context "on failure" do
      let(:track_user) { ->(name:, email:) { Failure("something") } }
      let(:dependencies) { { track_user: track_user } }

      it "returns the input" do
        expect(result).to eql(Failure("something"))
      end
    end
  end

  describe "merge" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)
        merge :user
      end.new(**dependencies)
    end

    let(:input) { { name: "Jane", email: "jane@doe.com" } }
    subject(:result) { transaction.call(input) }

    context "on failure" do
      let(:user_op) { ->(name:, email:) { Failure("something") } }
      let(:dependencies) { { user: user_op } }

      it "returns the input" do
        expect(result).to eql(Failure("something"))
      end
    end

    context "on success" do
      let(:user_op) { ->(name:, email:) { { user: "something" } } }
      let(:dependencies) { { user: user_op } }

      it "merges the input and output" do
        expect(result).to eql(Success({ name: "Jane", email: "jane@doe.com", user: "something" }))
      end
    end
  end
end
