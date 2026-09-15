# frozen_string_literal: true

require "test_helper"

module Citizen
  class MembersPageTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
    end

    teardown { Citizen.reset! }

    test "a member who can manage members opens the members page" do
      manager = ::Member.create!
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { member_id: manager.id, account_id: 1 }

      assert_response :success
    end

    test "a member who cannot manage members is refused the members page" do
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Viewer", capabilities: []))

      get "/citizen/members", params: { member_id: member.id, account_id: 1 }

      assert_response :forbidden
    end

    test "the members page is refused when no current account is set" do
      manager = ::Member.create!
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))

      get "/citizen/members", params: { member_id: manager.id }

      assert_response :forbidden
    end

    test "the members page lists each member of the current account by name" do
      manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      ::Member.create!(account_id: 1, name: "Pretend Person")

      get "/citizen/members", params: { member_id: manager.id, account_id: 1 }

      assert_includes response.body, "Pretend Person"
    end
  end
end
