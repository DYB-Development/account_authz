# frozen_string_literal: true

require "test_helper"

module Citizen
  class GiveRoleTest < ActiveSupport::TestCase
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
      @role = Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
    end

    teardown { Citizen.reset! }

    test "giving a role puts it on the person" do
      GiveRole.new(person: @manager, account: 1, values: { member_id: @person.id, role_id: @role.id }).call

      assert_includes @person.citizen_roles.in_account(1), @role
    end
  end
end
