# frozen_string_literal: true

require "test_helper"

module Citizen
  class RemoveMemberTest < ActiveSupport::TestCase
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
    end

    teardown { Citizen.reset! }

    test "removing a person takes them off the account" do
      RemoveMember.new(person: @manager, account: 1, values: { member_id: @person.id }).call

      assert_nil @person.reload.account_id
    end
  end
end
