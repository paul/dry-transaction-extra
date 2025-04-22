# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Maybe Step" do
  subject(:result) { transaction.call(input) }

  include_context "test_transaction"
  include Dry::Monads[:result]

  let(:dependencies) { {} }
  let(:optional_transaction) do
    Class.new(Test::Transaction) do
      validate do
        params do
          required(:email).filled(:string)
        end
      end

      step :result

      def result(_input = {}) = Success("result")
    end
  end

  let(:input) { { name: "Jane", email: "jane@doe.com" } }

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

      context "if the txn fails" do
        let(:optional_transaction) do
          Class.new(Test::Transaction) do
            validate do
              params do
                required(:name).filled(:string)
              end
            end

            step :result

            def result(_input = {}) = Failure("💣")
          end
        end

        it "fails the maybe step" do
          expect(result).to eql(Failure("💣"))
        end
      end
    end

    context "when the other txn's validator fails" do
      let(:input) { { name: "Jane", email: nil } }

      it "passes the original input through" do
        expect(result).to eql(Success(name: "Jane", email: nil))
      end
    end

    describe "building a new input" do
      let(:transaction) do
        Class.new(Test::Transaction) do
          maybe OptionalTransaction, build_input: :build_other_input, as: :optional

          private
          def build_other_input(email:, **)
            { email:, role: :admin }
          end
        end
      end

      it "passes modified input params" do
        allow(optional_transaction).to receive(:call)

        result

        expect(optional_transaction)
          .to have_received(:call)
          .with(email: "jane@doe.com", role: :admin)
      end

      it "merges the result of the other transaction" do
        expect(result).to eql(Success(name: "Jane", email: "jane@doe.com",
                                      optional: "result"))
      end
    end
  end
end
