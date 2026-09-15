# frozen_string_literal: true

require "test_helper"

module Citizen
  class MemberRolesTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
      @role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])
    end

    teardown { Citizen.reset! }

    test "a manager gives a member one of the current account's roles" do
      post "/citizen/members/#{@person.id}/roles", params: { role_id: @role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_includes @person.citizen_roles, @role
    end
  end
end
