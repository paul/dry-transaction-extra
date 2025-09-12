# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dry::Transaction::Extra::Steps::Merge, :adapter do
  let(:options) { { step_name: "test" } }
  let(:operation) { ->(*) {} }
  let(:input) { [{ answer: 42 }] }

  subject(:result) { described_class.new.call(operation, options, input) }

  describe "#call" do
    context "when operation succeeds" do
      let(:operation) { ->(_input) { { result: "success" } } }

      it "returns the merged input and output as Success" do
        expect(result).to eql(Success({ answer: 42, result: "success" }))
      end

      describe "hash output" do
        let(:operation) { ->(_input) { { result: 'success' } } }
        it "merges the hash with the input args" do
          expect(result).to eql(Success({ answer: 42, result: "success" }))
        end

        describe "as: option" do
          let(:options) { { step_name: "test", as: "my_key" } }
          it "uses the alias as the key" do
            expect(result).to eql(Success({ answer: 42, my_key: { result: "success" } }))
          end
        end
      end

      describe "non-hash output" do
        let(:operation) { ->(_input) { "success" } }
        it "uses the step name as the key" do
          expect(result).to eql(Success({ answer: 42, test: "success" }))
        end

        describe "as: option" do
          let(:options) { { step_name: "test", as: "my_key" } }
          it "uses the alias as the key" do
            expect(result).to eql(Success({ answer: 42, my_key: "success" }))
          end
        end
      end
    end

    context "when the operation fails" do
      let(:operation) { ->(_input) { Failure("oops") } }

      it "returns the original input as Success" do
        expect(result).to eql(Failure("oops"))
      end
    end

    context "with non-kwargs" do
      it "allows empty args" do
        expect(described_class.new.call(operation, options, [])).to eql(Success({ test: nil }))
      end

      it "errors on non-keyword args" do
        expect { described_class.new.call(operation, options, [1]) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
