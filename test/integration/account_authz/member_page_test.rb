# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class MemberPageTest < ActionDispatch::IntegrationTest
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
    end

    teardown { AccountAuthz.reset! }

    test "a manager opens a member's page and sees a role they hold" do
      person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
      role = Role.create!(account_id: 1, name: "Editor", capabilities: [])
      person.assign_role(role)

      get "/account_authz/members/#{person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_select "body", text: /Editor/
    end

    test "a manager is offered a role the person does not hold" do
      person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
      role = Role.create!(account_id: 1, name: "Editor", capabilities: [])

      get "/account_authz/members/#{person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_select "form[action=?][method=post] input[name=role_id][value=?]", "/account_authz/members/#{person.id}/roles", role.id.to_s
    end

    test "a manager can remove the person from the team on their page" do
      person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")

      get "/account_authz/members/#{person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_select "form[action=?] input[name=_method][value=delete]", "/account_authz/members/#{person.id}"
    end
  end
end
