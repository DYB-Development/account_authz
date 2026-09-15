# frozen_string_literal: true

require "test_helper"

module Citizen
  class InvitationsTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
    end

    teardown { Citizen.reset! }

    test "a manager invites a person to the account by name and email" do
      post "/citizen/invitations", params: { invitation: { name: "Pretend Person", email: "pretend@example.com" }, signed_in_member_id: @manager.id, account_id: 1 }

      assert ::Member.exists?(account_id: 1, email: "pretend@example.com")
    end
  end
end
