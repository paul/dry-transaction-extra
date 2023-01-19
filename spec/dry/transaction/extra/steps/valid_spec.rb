# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dry::Transaction::Extra::Steps::Valid, :adapter do
  let(:options) { { step_name: "test" } }
  let(:operation) { ->(**) { validator } }
  let(:input) { [{ name: "Paul" }] }
  let(:validator) do
    Dry::Schema::Params() do
      required(:name).filled(:string)
      optional(:email).maybe(:string)
    end
  end

  subject(:result) { described_class.new.call(operation, options, input) }

  describe "#call" do
    context "with valid input" do
      it "returns the validator output as Success" do
        expect(result).to eql(Success({ name: "Paul" }))
      end
    end

    context "with invalid input" do
      let(:input) { [{ name: nil }] }

      it "returns the validator errors as Failure" do
        expect(result.failure?).to be_truthy
        expect(result.failure).to be_a(Dry::Schema::Result)
      end
    end

    context "with non-hash arguments" do
      it "raises an error" do
        expect { described_class.new.call(operation, options, [1]) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
