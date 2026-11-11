# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class ActionPermissionsTest < ActionDispatch::IntegrationTest
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { metric :revenue }
    end

    teardown { AccountAuthz.reset! }

    test "a member holding an action's permission opens it" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))

      get "/ledger", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :ok
    end
  end
end
