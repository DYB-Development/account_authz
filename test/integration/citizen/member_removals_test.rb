# frozen_string_literal: true

require "test_helper"

module Citizen
  class MemberRemovalsTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members]))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
    end

    teardown { Citizen.reset! }

    test "a manager removes a member from the account" do
      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_nil @person.reload.account_id
    end
  end
end
