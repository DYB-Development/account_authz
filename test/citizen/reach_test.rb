# frozen_string_literal: true

require "test_helper"

module Citizen
  class ReachTest < ActiveSupport::TestCase
    setup do
      @lead = ::Member.create!(account_id: 1, name: "Pretend Lead")
      @lead.assign_role(Role.create!(account_id: 1, name: "Lead", rank: 1, capabilities: []))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
    end

    test "a manager reaches a member whose highest role ranks below theirs" do
      @person.assign_role(Role.create!(account_id: 1, name: "Worker", rank: 0, capabilities: []))
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert Reach.new(@lead, account_id: 1).includes_member?(@person)
    end

    test "a manager reaches a member who holds no role in the account" do
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert Reach.new(@lead, account_id: 1).includes_member?(@person)
    end
  end
end
