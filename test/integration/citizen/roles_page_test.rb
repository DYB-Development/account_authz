# frozen_string_literal: true

require "test_helper"

module Citizen
  class RolesPageTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog do
        permission :manage_roles
        permission :view_reports
      end
      @admin = ::Member.create!(account_id: 1, name: "Pretend Admin")
      @admin.assign_role(Role.create!(account_id: 1, name: "Admin", capabilities: %w[manage_roles]))
    end

    teardown { Citizen.reset! }

    test "a member who can manage roles opens the roles page" do
      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_response :success
    end

    test "a member who cannot manage roles is refused the roles page" do
      member = ::Member.create!(account_id: 1, name: "Pretend Person")

      get "/citizen/roles", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :forbidden
    end

    test "the roles page opens for the capability the app names for managing roles" do
      Citizen.catalog { permission :manage_team }
      Citizen.roles_capability = :manage_team
      lead = ::Member.create!(account_id: 1, name: "Pretend Lead")
      lead.assign_role(Role.create!(account_id: 1, name: "Lead", capabilities: %w[manage_team]))

      get "/citizen/roles", params: { signed_in_member_id: lead.id, account_id: 1 }

      assert_response :success
    end

    test "the roles page lists the current account's roles" do
      Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_includes response.body, "Pretend Role"
    end

    test "the roles page leaves out another account's roles" do
      Role.create!(account_id: 2, name: "Other Account Role", capabilities: [])

      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_not_includes response.body, "Other Account Role"
    end

    test "a member who can manage roles creates a role in the current account" do
      post "/citizen/roles", params: { role: { name: "Pretend Role" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert Role.in_account(1).exists?(name: "Pretend Role")
    end

    test "a new role holds the capabilities chosen for it" do
      post "/citizen/roles", params: { role: { name: "Pretend Role", capabilities: %w[view_reports] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal %w[view_reports], Role.in_account(1).find_by(name: "Pretend Role").capabilities
    end

    test "a member who can manage roles adds a role from a template" do
      Citizen.templates { template :reporter, capabilities: %w[view_reports] }

      post "/citizen/roles", params: { template: "reporter", signed_in_member_id: @admin.id, account_id: 1 }

      assert Role.in_account(1).exists?(name: "Reporter")
    end

    test "a member who cannot manage roles cannot create a role" do
      member = ::Member.create!(account_id: 1, name: "Pretend Person")

      post "/citizen/roles", params: { role: { name: "Pretend Role" }, signed_in_member_id: member.id, account_id: 1 }

      assert_not Role.exists?(name: "Pretend Role")
    end

    test "a member who can manage roles renames a role" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Renamed Role" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal "Renamed Role", role.reload.name
    end
  end
end
