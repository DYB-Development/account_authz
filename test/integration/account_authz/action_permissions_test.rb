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

    test "a member without an action's permission is refused" do
      member = ::Member.create!

      get "/ledger", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :forbidden
    end

    test "an action that names no permission is refused" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))

      get "/ledger/edit", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :forbidden
    end

    test "a member with no permissions opens an action open to every member" do
      member = ::Member.create!

      get "/ledgers", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :ok
    end

    test "a controller chooses how a refused action answers" do
      member = ::Member.create!

      get "/hidden_ledger", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :not_found
    end
  end
end
