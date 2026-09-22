# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class InviteTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
    end

    teardown { AccountAuthz.reset! }

    test "inviting someone adds them to the invitations waiting for an answer" do
      Invite.new(person: @manager, account: 1, values: { name: "Pretend Person", email: "pretend@example.com" }).call

      assert_includes AccountAuthz.members_source.invitations(1).map(&:email), "pretend@example.com"
    end
  end
end
