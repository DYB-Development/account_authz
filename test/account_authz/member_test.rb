# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class MemberTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog do
        metric :revenue
        metric :tickets
        metric :fulfillment
      end
    end

    teardown { AccountAuthz.reset! }

    test "assigning a role makes it one of the member's roles" do
      role = Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue])
      member = ::Member.create!

      member.assign_role(role)

      assert_includes member.account_authz_roles, role
    end

    test "capabilities is the union of assigned roles' capabilities as symbols" do
      sales = Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue])
      support = Role.create!(account_id: 1, name: "Support", capabilities: %w[revenue tickets])
      member = ::Member.create!

      member.assign_role(sales)
      member.assign_role(support)

      assert_equal %i[revenue tickets], member.capabilities.sort
    end

    test "can? is true only for capabilities the member's roles grant" do
      role = Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue])
      member = ::Member.create!
      member.assign_role(role)

      assert member.can?(:revenue)
      assert_not member.can?(:expenses)
    end

    test "revoking a role removes it from the member's roles" do
      role = Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue])
      member = ::Member.create!
      member.assign_role(role)

      member.revoke_role(role)

      assert_not_includes member.reload.account_authz_roles, role
    end

    test "approved_metrics are the member's granted catalog metrics" do
      AccountAuthz.reset!
      AccountAuthz.catalog do
        permission :view_fulfillment
        metric :revenue
        metric :deals
      end
      role = Role.create!(account_id: 1, name: "Sales", capabilities: %w[view_fulfillment revenue])
      member = ::Member.create!
      member.assign_role(role)

      assert_equal %i[revenue], member.approved_metrics
    ensure
      AccountAuthz.reset!
    end

    test "capabilities can be scoped to a single account" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))
      member.assign_role(Role.create!(account_id: 2, name: "Ops", capabilities: %w[fulfillment]))

      assert_equal %i[revenue], member.capabilities(account_id: 1)
    end
  end
end
