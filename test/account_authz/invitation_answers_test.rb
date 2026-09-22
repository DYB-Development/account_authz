# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class InvitationAnswersTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
      @invitation = ::Invitation.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    end

    teardown { AccountAuthz.reset! }

    test "sending an invitation again counts another send" do
      ResendInvitation.new(person: @manager, account: 1, values: { invitation_id: @invitation.id }).call

      assert_equal 2, @invitation.reload.sent_count
    end

    test "cancelling an invitation drops it" do
      CancelInvitation.new(person: @manager, account: 1, values: { invitation_id: @invitation.id }).call

      assert_empty AccountAuthz.members_source.invitations(1)
    end
  end
end
