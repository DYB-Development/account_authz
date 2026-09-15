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

    test "a manager does not reach a member at their own rank" do
      @person.assign_role(Role.create!(account_id: 1, name: "Co-lead", rank: 1, capabilities: []))
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert_not Reach.new(@lead, account_id: 1).includes_member?(@person)
    end

    test "a manager at the account's top rank reaches a member at the same rank" do
      @person.assign_role(Role.create!(account_id: 1, name: "Co-lead", rank: 1, capabilities: []))

      assert Reach.new(@lead, account_id: 1).includes_member?(@person)
    end

    test "a manager reaches a role ranked below their highest role" do
      worker = Role.create!(account_id: 1, name: "Worker", rank: 0, capabilities: [])
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert Reach.new(@lead, account_id: 1).includes_role?(worker)
    end

    test "a manager at the account's top rank reaches a role at the same rank" do
      co_lead = Role.create!(account_id: 1, name: "Co-lead", rank: 1, capabilities: [])

      assert Reach.new(@lead, account_id: 1).includes_role?(co_lead)
    end

    test "a manager does not reach a role at their own rank" do
      co_lead = Role.create!(account_id: 1, name: "Co-lead", rank: 1, capabilities: [])
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert_not Reach.new(@lead, account_id: 1).includes_role?(co_lead)
    end

    test "ranks held in another account do not count" do
      @lead.assign_role(Role.create!(account_id: 2, name: "Elsewhere Owner", rank: 9, capabilities: []))
      @person.assign_role(Role.create!(account_id: 1, name: "Co-lead", rank: 1, capabilities: []))
      Role.create!(account_id: 1, name: "Owner", rank: 2, capabilities: [])

      assert_not Reach.new(@lead, account_id: 1).includes_member?(@person)
    end
  end
end
