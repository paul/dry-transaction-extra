# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Valid Step" do
  include_context "test_transaction"
  include Dry::Monads[:result]

  let(:dependencies) { {} }

  let(:input) { { "name" => "Jane", "email" => "jane@doe.com" } }
  subject(:result) { transaction.call(input) }

  describe "schema defined in step method" do
    let(:transaction) do
      Class.new(Test::Transaction) do
        valid :params

        def params(_input = {})
          Dry::Schema::Params() do
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
        expect(result.failure).to be_a(Dry::Schema::Result)
      end
    end
  end

  describe "schema provided to step DSL" do
    before do
      validator = Dry::Schema::Params() do
        required(:name).filled(:string)
        optional(:email).maybe(:string)
      end
      stub_const("Validator", validator)
    end

    let(:transaction) do
      Class.new(test_transaction) do
        valid Validator
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
        expect(result.failure).to be_a(Dry::Schema::Result)
      end
    end
  end
end
