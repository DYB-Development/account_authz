# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class SeedingTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { metric :revenue }
      AccountAuthz.templates do
        template :admin, capabilities: %w[revenue], default: true
        template :custom, capabilities: %w[revenue]
      end
    end

    teardown { AccountAuthz.reset! }

    test "seeds a role only for each default template" do
      AccountAuthz.seed_default_roles(42)

      assert_equal %w[Admin], Role.in_account(42).pluck(:name)
    end

    test "seeding twice does not duplicate roles" do
      AccountAuthz.seed_default_roles(42)
      AccountAuthz.seed_default_roles(42)

      assert_equal 1, Role.in_account(42).count
    end

    test "seeding one account does not create roles in another" do
      AccountAuthz.seed_default_roles(42)

      assert_equal 0, Role.in_account(99).count
    end
  end
end
