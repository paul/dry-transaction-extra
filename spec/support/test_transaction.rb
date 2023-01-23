# frozen_string_literal: true

RSpec.shared_context "test_transaction" do
  include_context "container"

  before do
    txn = Class.new do
      include Dry::Transaction(container: Test::Container)
      include Dry::Transaction::Extra
    end
    txn.load_extensions :validation
    txn.load_extensions :class_callable
    stub_const "Test::Transaction", txn
  end

  let(:test_transaction) { Test::Transaction }
end
