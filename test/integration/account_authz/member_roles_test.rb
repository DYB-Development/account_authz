# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class MemberRolesTest < ActionDispatch::IntegrationTest
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
      @role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])
    end

    teardown { AccountAuthz.reset! }

    test "a manager gives a member one of the current account's roles" do
      post "/account_authz/members/#{@person.id}/roles", params: { role_id: @role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_includes @person.account_authz_roles, @role
    end

    test "a member who cannot manage members cannot give a role" do
      post "/account_authz/members/#{@person.id}/roles", params: { role_id: @role.id, signed_in_member_id: @person.id, account_id: 1 }

      assert_empty @person.account_authz_roles
    end

    test "a manager cannot give a member a role from another account" do
      other_role = Role.create!(account_id: 2, name: "Other Account Role", capabilities: [])

      post "/account_authz/members/#{@person.id}/roles", params: { role_id: other_role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_empty @person.account_authz_roles
    end

    test "a manager cannot give a role to a member of another account" do
      outsider = ::Member.create!(account_id: 2, name: "Pretend Outsider")

      post "/account_authz/members/#{outsider.id}/roles", params: { role_id: @role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_empty outsider.account_authz_roles
    end

    test "a manager takes a role away from a member" do
      @person.assign_role(@role)

      delete "/account_authz/members/#{@person.id}/roles/#{@role.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_empty @person.account_authz_roles
    end

    test "a member who cannot manage members cannot take a role away" do
      @person.assign_role(@role)

      delete "/account_authz/members/#{@person.id}/roles/#{@role.id}", params: { signed_in_member_id: @person.id, account_id: 1 }

      assert_includes @person.account_authz_roles, @role
    end

    test "a manager cannot give a role ranked at or above their own" do
      owner = Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: [])

      post "/account_authz/members/#{@person.id}/roles", params: { role_id: owner.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_empty @person.account_authz_roles
    end

    test "a manager cannot take away a role ranked at or above their own" do
      owner = Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: [])
      @person.assign_role(owner)

      delete "/account_authz/members/#{@person.id}/roles/#{owner.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_includes @person.account_authz_roles, owner
    end

    test "a manager cannot change the roles of a member ranked at or above them" do
      @manager.assign_role(Role.create!(account_id: 1, name: "Lead", rank: 1, capabilities: []))
      @person.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: []))

      post "/account_authz/members/#{@person.id}/roles", params: { role_id: @role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_not_includes @person.account_authz_roles, @role
    end

    test "the only manager cannot take away their own members role" do
      manager_role = @manager.account_authz_roles.first

      delete "/account_authz/members/#{@manager.id}/roles/#{manager_role.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_includes @manager.account_authz_roles, manager_role
    end

    test "a manager refused a role ranked at or above their own is told why" do
      owner = Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: [])

      post "/account_authz/members/#{@person.id}/roles", params: { role_id: owner.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "You can only give or take roles ranked below your own.", flash[:alert]
    end

    test "a manager refused changes to a member ranked at or above them is told why" do
      @manager.assign_role(Role.create!(account_id: 1, name: "Lead", rank: 1, capabilities: []))
      @person.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: []))

      post "/account_authz/members/#{@person.id}/roles", params: { role_id: @role.id, signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "You can only change members ranked below you.", flash[:alert]
    end

    test "the only manager refused taking away their members role is told why" do
      manager_role = @manager.account_authz_roles.first

      delete "/account_authz/members/#{@manager.id}/roles/#{manager_role.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "Someone else needs to be able to manage members first.", flash[:alert]
    end
  end
end
