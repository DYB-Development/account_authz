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

    test "a removed member loses the roles they held in the account" do
      @person.assign_role(Role.create!(account_id: 1, name: "Worker", capabilities: []))

      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_empty @person.citizen_roles.in_account(1)
    end

    test "a manager cannot remove a member ranked at or above them" do
      @person.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: []))

      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal 1, @person.reload.account_id
    end

    test "nobody can remove the account owner" do
      @person.update!(owner: true)

      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal 1, @person.reload.account_id
    end

    test "a member who cannot manage members cannot remove anyone" do
      @person.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: []))

      delete "/citizen/members/#{@manager.id}", params: { signed_in_member_id: @person.id, account_id: 1 }

      assert_equal 1, @manager.reload.account_id
    end

    test "the only manager cannot be removed from the account" do
      delete "/citizen/members/#{@manager.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal 1, @manager.reload.account_id
    end

    test "a manager refused removing a member ranked at or above them is told why" do
      @person.assign_role(Role.create!(account_id: 1, name: "Owner", rank: 1, capabilities: []))

      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "You can only change members ranked below you.", flash[:alert]
    end

    test "a manager refused removing the account owner is told why" do
      @person.update!(owner: true)

      delete "/citizen/members/#{@person.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "This member can't be removed from the account.", flash[:alert]
    end

    test "the only manager refused removal is told why" do
      delete "/citizen/members/#{@manager.id}", params: { signed_in_member_id: @manager.id, account_id: 1 }

      assert_equal "Someone else needs to be able to manage members first.", flash[:alert]
    end
  end
end
