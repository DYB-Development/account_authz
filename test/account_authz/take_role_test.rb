# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class TakeRoleTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
      @role = Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
      @person.assign_role(@role)
    end

    teardown { AccountAuthz.reset! }

    test "taking a role removes it from the person" do
      TakeRole.new(person: @manager, account: 1, values: { member_id: @person.id, role_id: @role.id }).call

      assert_not_includes @person.reload.account_authz_roles.in_account(1), @role
    end

    test "taking the last role that manages members is refused" do
      result = TakeRole.new(person: @manager, account: 1, values: { member_id: @manager.id, role_id: @manager.account_authz_roles.first.id }).call

      assert_not result.ok?
    end
  end
end
