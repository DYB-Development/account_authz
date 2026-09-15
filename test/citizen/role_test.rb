# frozen_string_literal: true

require "test_helper"

module Citizen
  class RoleTest < ActiveSupport::TestCase
    setup do
      Citizen.reset!
      Citizen.catalog do
        metric :revenue
        metric :deals
      end
    end

    teardown { Citizen.reset! }

    test "rejects a capability that is not in the catalog" do
      role = Role.new(account_id: 1, name: "Bogus", capabilities: %w[not_a_capability])
      role.valid?

      assert_includes role.errors[:capabilities], "includes unknown capability: not_a_capability"
    end

    test "from_template builds a role with the template's capabilities" do
      Citizen.templates do
        template :sales, capabilities: %w[revenue deals]
      end

      role = Role.from_template(account_id: 7, template: :sales)

      assert_equal %w[revenue deals], role.capabilities
    end

    test "from_template titleizes the template key into the role name" do
      Citizen.templates do
        template :sales_associate, capabilities: %w[revenue]
      end

      role = Role.from_template(account_id: 7, template: :sales_associate)

      assert_equal "Sales Associate", role.name
    end

    test "stores its capabilities" do
      role = Role.create!(account_id: 1, name: "Sales Associate", capabilities: %w[revenue deals])

      assert_equal %w[revenue deals], role.reload.capabilities
    end

    test "requires a name" do
      role = Role.new(account_id: 1)
      role.valid?

      assert_includes role.errors[:name], "can't be blank"
    end

    test "in_account returns only roles for that account" do
      mine = Role.create!(account_id: 1, name: "Mine")
      Role.create!(account_id: 2, name: "Theirs")

      assert_equal [ mine ], Role.in_account(1).to_a
    end

    test "a new role sits at the bottom rank" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      assert_equal 0, role.rank
    end
  end
end
