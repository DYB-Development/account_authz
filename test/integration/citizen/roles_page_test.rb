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
      @admin.assign_role(Role.create!(account_id: 1, name: "Admin", rank: 3, capabilities: %w[manage_roles view_reports]))
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

    test "a member who can manage roles cannot change another account's role" do
      role = Role.create!(account_id: 2, name: "Other Account Role", capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Renamed Role" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal "Other Account Role", role.reload.name
    end

    test "unticking every capability on a role leaves it with none" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: %w[view_reports])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Pretend Role", capabilities: [ "" ] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_empty role.reload.capabilities
    end

    test "the new role form offers a checkbox for each capability in the catalog" do
      get "/citizen/roles/new", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal %w[manage_roles view_reports], css_select("form[action='/citizen/roles'] input[type=checkbox][name='role[capabilities][]']").map { |box| box["value"] }
    end

    test "the edit role form ticks the capabilities the role holds" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: %w[view_reports])

      get "/citizen/roles/#{role.id}/edit", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal %w[view_reports], css_select("form[action='/citizen/roles/#{role.id}'] input[type=checkbox][checked]").map { |box| box["value"] }
    end

    test "the roles page offers to add each default template" do
      Citizen.templates { template :reporter, capabilities: %w[view_reports], default: true }

      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_select "form[action='/citizen/roles'][method=post] input[name=template][value=reporter]"
    end

    test "the roles page links to each role's edit form" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_select "a[href=?]", "/citizen/roles/#{role.id}/edit"
    end

    test "the roles page links to the new role form" do
      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_select "a[href=?]", "/citizen/roles/new"
    end

    test "the roles page leaves out the templates section when the app has no default templates" do
      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_not_includes response.body, "Templates"
    end

    test "a member who can manage roles sets a role's rank" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Pretend Role", rank: "2" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal 2, role.reload.rank
    end

    test "the edit role form shows the role's rank" do
      role = Role.create!(account_id: 1, name: "Pretend Role", rank: 3, capabilities: [])

      get "/citizen/roles/#{role.id}/edit", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_select "input[name='role[rank]'][value='3']"
    end

    test "the members capability cannot be taken off the only role that lets anyone manage members" do
      Citizen.catalog { permission :manage_members }
      manager_role = Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members])
      @admin.assign_role(manager_role)

      patch "/citizen/roles/#{manager_role.id}", params: { role: { name: "Manager", capabilities: [ "" ] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal %w[manage_members], manager_role.reload.capabilities
    end

    test "a manager refused taking the members capability off the only role that grants it is told why" do
      Citizen.catalog { permission :manage_members }
      manager_role = Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members])
      @admin.assign_role(manager_role)

      patch "/citizen/roles/#{manager_role.id}", params: { role: { name: "Manager", capabilities: [ "" ] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal "Someone else needs to be able to manage members first.", flash[:alert]
    end

    test "an editor is refused a new role with a capability they do not hold" do
      Citizen.catalog { permission :export_data }

      post "/citizen/roles", params: { role: { name: "Pretend Role", capabilities: %w[export_data] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_not Role.exists?(name: "Pretend Role")
    end

    test "an editor is refused adding a capability they do not hold to a role" do
      Citizen.catalog { permission :export_data }
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Pretend Role", capabilities: %w[export_data] }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_empty role.reload.capabilities
    end

    test "an editor is refused setting a role's rank above their own" do
      role = Role.create!(account_id: 1, name: "Pretend Role", capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Pretend Role", rank: "5" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal 0, role.reload.rank
    end

    test "an editor is refused a new role ranked above their own" do
      post "/citizen/roles", params: { role: { name: "Pretend Role", rank: "5" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_not Role.exists?(name: "Pretend Role")
    end

    test "an editor is refused changing a role ranked above their own" do
      Role.create!(account_id: 1, name: "Owner", rank: 9, capabilities: [])
      role = Role.create!(account_id: 1, name: "Senior", rank: 4, capabilities: [])

      patch "/citizen/roles/#{role.id}", params: { role: { name: "Renamed" }, signed_in_member_id: @admin.id, account_id: 1 }

      assert_equal "Senior", role.reload.name
    end

    test "an editor is refused a template role with a capability they do not hold" do
      Citizen.catalog { permission :export_data }
      Citizen.templates { template :exporter, capabilities: %w[export_data] }

      post "/citizen/roles", params: { template: "exporter", signed_in_member_id: @admin.id, account_id: 1 }

      assert_not Role.exists?(name: "Exporter")
    end

    test "the roles page links back to the members page" do
      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_select "a[href='/citizen/members']", text: "Members"
    end
  end
end
