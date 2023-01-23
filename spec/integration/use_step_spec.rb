# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Use Step" do
  include_context "test_transaction"
  include Dry::Monads[:result]

  let(:dependencies) { {} }

  let(:input) { { name: "Jane", email: "jane@doe.com" } }
  subject(:result) { transaction.call(input) }

  let(:other_transaction) do
    Class.new(Test::Transaction) do
      step :result

      def result(_input = {}) = Success("result")
    end
  end

  before do
    stub_const "OtherTransaction", other_transaction
  end

  describe "invoking a transaction" do
    let(:transaction) do
      Class.new(Test::Transaction) do
        use OtherTransaction
      end
    end

    it "merges the result of the other transaction" do
      expect(result).to eql(Success(name: "Jane", email: "jane@doe.com",
                                    OtherTransaction: "result"))
    end
  end

  describe "invoking any other callable" do
    let(:transaction) do
      Class.new(Test::Transaction) do
        use ->(_) { "lambda" }, as: :lambda
      end
    end

    it "merges the result of the other transaction" do
      expect(result).to eql(Success(name: "Jane", email: "jane@doe.com",
                                    lambda: "lambda"))
    end
  end

  describe "container lookup" do
    before do
      container = Class.new do
        extend Dry::Container::Mixin
        register(:find_user) { ->(_) { "some user" } }
      end

      stub_const "MyContainer", container
    end
    let(:transaction) do
      Class.new(Test::Transaction) do
        use MyContainer, :find_user
      end
    end

    it "merges the result of the other transaction" do
      expect(result).to eql(Success(name: "Jane", email: "jane@doe.com",
                                    "MyContainer.find_user": "some user"))
    end
  end
end
