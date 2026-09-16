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

      assert ::Invitation.exists?(account_id: 1, email: "pretend@example.com")
    end

    test "a member who cannot manage members cannot invite anyone" do
      person = ::Member.create!(account_id: 1, name: "Pretend Person")

      post "/citizen/invitations", params: { invitation: { name: "Pretend Guest", email: "guest@example.com" }, signed_in_member_id: person.id, account_id: 1 }

      assert_not ::Invitation.exists?(email: "guest@example.com")
    end

    test "a manager cancels an invitation still waiting for an answer" do
      invitation = ::Invitation.create!(account_id: 1, name: "Pretend Guest", email: "guest@example.com")

      delete "/citizen/invitations/#{invitation.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_not ::Invitation.exists?(invitation.id)
    end

    test "a manager sends an invitation again" do
      invitation = ::Invitation.create!(account_id: 1, name: "Pretend Guest", email: "guest@example.com")

      post "/citizen/invitations/#{invitation.id}/resend", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal 2, invitation.reload.sent_count
    end
  end
end
