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
      let(:track_user) { ->(name:, email:) { Success("something") } }
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
end
