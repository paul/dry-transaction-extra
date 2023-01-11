# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dry::Transaction::Extra::Steps::Tap, :adapter do
  let(:options) { {} }
  let(:operation) { ->(input) {} }
  let(:input) { 42 }

  subject(:result) { described_class.new.call(operation, options, input) }

  describe "#call" do
    context "when operation succeeds" do
      let(:operation) { ->(input) { input * 2 } }

      it "returns the original input as Success" do
        expect(result).to eql(Success(input))
      end
    end

    context "when the operation fails" do
      let(:operation) { ->(_input) { Failure("oops") } }

      it "returns the original input as Success" do
        expect(result).to eql(Failure("oops"))
      end
    end
  end
end
