# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Maybe Step" do
  include_context "test_transaction"
  include Dry::Monads[:result]

  let(:dependencies) { {} }

  let(:input) { { name: "Jane", email: "jane@doe.com" } }
  subject(:result) { transaction.call(input) }

  let(:optional_transaction) do
    Class.new(Test::Transaction) do
      validate do
        params do
          required(:name).filled(:string)
        end
      end

      step :result

      def result(_input = {}) = Success("result")
    end
  end

  before do
    stub_const "OptionalTransaction", optional_transaction
  end

  describe "invoking a transaction" do
    let(:transaction) do
      Class.new(Test::Transaction) do
        maybe OptionalTransaction
      end
    end

    context "when the other txn's validator passes" do
      it "merges the result of the other transaction" do
        expect(result).to eql(Success(name: "Jane", email: "jane@doe.com",
                                      OptionalTransaction: "result"))
      end
    end

    context "when the other txn's validator fails" do
      let(:input) { { name: nil, email: "jane@doe.com" } }
      it "should pass the original input through" do
        expect(result).to eql(Success(name: nil, email: "jane@doe.com"))
      end
    end
  end
end
