# frozen_string_literal: true

require "test_helper"

module Citizen
  class AuthorizationTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { metric :revenue }
    end

    teardown { Citizen.reset! }

    test "can? helper is available in the view and reflects the member's capabilities" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))

      get "/reports", params: { member_id: member.id, account_id: 1 }

      assert_includes response.body, "revenue: true"
    end

    test "can? helper resolves against the current account" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 2, name: "Sales", capabilities: %w[revenue]))

      get "/reports", params: { member_id: member.id, account_id: 1 }

      assert_includes response.body, "revenue: false"
    end

    test "can? helper denies when no current account is set" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))

      get "/reports", params: { member_id: member.id }

      assert_includes response.body, "revenue: false"
    end
  end
end
