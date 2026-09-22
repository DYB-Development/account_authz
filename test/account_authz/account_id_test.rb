# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class AccountIdTest < ActiveSupport::TestCase
    test "an account id is taken as it is" do
      assert_equal 1, AccountId.from(1)
    end

    test "an account record gives up its id" do
      account = ::Member.create!(account_id: 1, name: "Stands in for an account")

      assert_equal account.id, AccountId.from(account)
    end
  end
end
