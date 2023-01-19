# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Validation DSL" do
  include_context "test_transaction"
  include Dry::Monads[:result]

  let(:dependencies) { {} }

  let(:input) { { "name" => "Jane", "email" => "jane@doe.com" } }
  subject(:result) { transaction.call(input) }

  describe "validation defined inline" do
    let(:transaction) do
      Class.new(Test::Transaction) do
        validate do
          params do
            required(:name).filled(:string)
            optional(:email).maybe(:string)
          end
        end
      end.new(**dependencies)
    end

    context "with valid input" do
      it "returns the validator output as Success" do
        expect(result).to eql(Success(name: "Jane", email: "jane@doe.com"))
      end
    end

    context "with invalid input" do
      let(:input) { { name: nil } }

      it "returns the validator errors as Failure" do
        expect(result.failure?).to be_truthy
        expect(result.failure).to be_a(Dry::Validation::Result)
      end
    end

    it "allows the validator to be invoked outside the transaction" do
      result = transaction.class.validator.new.call(input)
      expect(result.to_h).to eql(name: "Jane", email: "jane@doe.com")
    end
  end

  describe "validation defined elsewhere" do
    before do
      validator = Class.new(Dry::Validation::Contract) do
        params do
          required(:name).filled(:string)
          optional(:email).maybe(:string)
        end
      end
      stub_const("Validator", validator)
    end

    let(:transaction) do
      Class.new(test_transaction) do
        validate Validator
      end.new(**dependencies)
    end

    context "with valid input" do
      it "returns the validator output as Success" do
        expect(result).to eql(Success(name: "Jane", email: "jane@doe.com"))
      end
    end

    context "with invalid input" do
      let(:input) { { name: nil } }

      it "returns the validator errors as Failure" do
        expect(result.failure?).to be_truthy
        expect(result.failure).to be_a(Dry::Validation::Result)
      end
    end

    it "allows the validator to be invoked outside the transaction" do
      result = transaction.class.validator.new.call(input)
      expect(result.to_h).to eql(name: "Jane", email: "jane@doe.com")
    end
  end
end
