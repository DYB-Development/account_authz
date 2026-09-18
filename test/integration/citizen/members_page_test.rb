# frozen_string_literal: true

require "test_helper"

module Citizen
  class MembersPageTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
    end

    teardown { Citizen.reset! }

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end


    test "a member who can manage members opens the members page" do
      manager = ::Member.create!
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_response :success
    end

    test "a member who cannot manage members is refused the members page" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Viewer", capabilities: []))

      get "/citizen/members", params: { signed_in_member_id: member.id, account_id: 1 }

      assert_response :forbidden
    end

    test "the members page is refused when no current account is set" do
      manager = ::Member.create!
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id }

      assert_response :forbidden
    end

    test "the members page lists each member of the current account by name" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      ::Member.create!(account_id: 1, name: "Pretend Person")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_includes response.body, "Pretend Person"
    end

    test "the members page lists the team as a table with a way into each person" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      person = ::Member.create!(account_id: 1, name: "Pretend Person")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "table tbody tr a[href=?]", "/citizen/members/#{person.id}"
    end

    test "the members page shows each member's email" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_includes response.body, "pretend@example.com"
    end

    test "the members page shows the roles each member holds" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      person = ::Member.create!(account_id: 1, name: "Pretend Person")
      person.assign_role(Role.create!(account_id: 1, name: "Pretend Role", capabilities: []))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_includes response.body, "Pretend Role"
    end

    test "the members page leaves out roles a member holds in another account" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      manager.assign_role(Role.create!(account_id: 2, name: "Other Account Role", capabilities: []))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_not_includes response.body, "Other Account Role"
    end

    test "the members page opens for the capability the app names for managing members" do
      Citizen.catalog { permission :manage_team }
      Citizen.members_capability = :manage_team
      lead = ::Member.create!(account_id: 1, name: "Pretend Lead")
      lead.assign_role(Role.create!(account_id: 1, name: "Lead", capabilities: %w[manage_team]))

      get "/citizen/members", params: { signed_in_member_id: lead.id, account_id: 1 }

      assert_response :success
    end

    test "the members page renders inside the app's layout" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "meta[name=application-name][content=Dummy]"
    end

    test "the app's layout reaches the app's own routes on the members page" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "a[href=?]", "/reports"
    end

    test "the members page does not offer to give a role ranked at or above the viewer's own" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      person = ::Member.create!(account_id: 1, name: "Pretend Person")
      owner = Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: [])

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?] input[name=role_id][value=?]", "/citizen/members/#{person.id}/roles", owner.id.to_s, count: 0
    end

    test "the members page does not offer to take away a role ranked at or above the viewer's own" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      person = ::Member.create!(account_id: 1, name: "Pretend Person")
      owner = Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: [])
      person.assign_role(owner)

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?]", "/citizen/members/#{person.id}/roles/#{owner.id}", count: 0
    end

    test "the members page offers no role changes for a member ranked at or above the viewer" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", rank: 1, capabilities: %w[manage_members]))
      Role.create!(account_id: 1, name: "Worker", rank: 0, capabilities: [])
      owner = ::Member.create!(account_id: 1, name: "Pretend Owner")
      owner.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: []))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action^=?]", "/citizen/members/#{owner.id}/roles", count: 0
    end

    test "the members page offers a button leading to the invitation form" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "a[href=?]", "/citizen/invitations/new", text: "Invite"
    end

    test "the members page does not offer to remove the account owner" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      owner = ::Member.create!(account_id: 1, name: "Pretend Owner", owner: true)

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?]", "/citizen/members/#{owner.id}", count: 0
    end

    test "the members page does not offer the only manager a way to take away their members role" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager_role = Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members])
      manager.assign_role(manager_role)

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?]", "/citizen/members/#{manager.id}/roles/#{manager_role.id}", count: 0
    end

    test "the members page does not offer to remove the only manager" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?]", "/citizen/members/#{manager.id}", count: 0
    end

    test "the members page links a viewer who can manage roles to the roles page" do
      Citizen.catalog { permission :manage_roles }
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members manage_roles]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "a[href='/citizen/roles']", text: "Roles"
    end

    test "the members page does not link a viewer who cannot manage roles to the roles page" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "a[href='/citizen/roles']", count: 0
    end

    test "the members page lists an invitation still waiting for an answer" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      ::Invitation.create!(account_id: 1, name: "Pretend Guest", email: "guest@example.com")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_includes response.body, "guest@example.com"
    end

    test "the members page offers to cancel an invitation still waiting for an answer" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      invitation = ::Invitation.create!(account_id: 1, name: "Pretend Guest", email: "guest@example.com")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?] input[name=_method][value=delete]", "/citizen/invitations/#{invitation.id}"
    end

    test "the members page offers to send an invitation again" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      invitation = ::Invitation.create!(account_id: 1, name: "Pretend Guest", email: "guest@example.com")

      get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action=?][method=post]", "/citizen/invitations/#{invitation.id}/resend"
    end

    test "listing more members does not run more role queries" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      role = Role.create!(account_id: 1, name: "Worker", capabilities: [])
      ::Member.create!(account_id: 1, name: "Pretend One").assign_role(role)

      one = count_role_queries { get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 } }
      ::Member.create!(account_id: 1, name: "Pretend Two").assign_role(role)
      ::Member.create!(account_id: 1, name: "Pretend Three").assign_role(role)

      assert_equal one, count_role_queries { get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 } }
    end

    private

    def count_role_queries
      count = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        count += 1 if payload[:sql].include?("citizen_assignments") || payload[:sql].include?("citizen_roles")
      end
      yield
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    test "the invitation page offers a form to invite a person by email" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/invitations/new", params: { signed_in_member_id: manager.id, account_id: 1 }

      assert_select "form[action='/citizen/invitations'][method=post] input[name='invitation[email]']"
    end

    test "the members page asks for nothing the list does not show" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      Role.create!(account_id: 1, name: "Editor", capabilities: [])

      count = count_queries { get "/citizen/members", params: { signed_in_member_id: manager.id, account_id: 1 } }

      assert_operator count, :<=, 10
    end
  end
end
