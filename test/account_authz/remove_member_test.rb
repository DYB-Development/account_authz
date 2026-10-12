# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class RemoveMemberTest < ActiveSupport::TestCase
    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog { permission :manage_members }
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 1))
      @person = ::Member.create!(account_id: 1, name: "Pretend Person")
    end

    teardown { AccountAuthz.reset! }

    test "removing a person takes them off the account" do
      RemoveMember.new(person: @manager, account: 1, values: { member_id: @person.id }).call

      assert_nil @person.reload.account_id
    end

    test "removing asks a source that answers the member lookup for the member at the address" do
      person = @person
      source = Class.new(MemberDirectory) do
        define_singleton_method(:member) { |account_id, address| address == "pretend-code" ? members(account_id).find(person.id) : raise(ActiveRecord::RecordNotFound) }
      end
      was = AccountAuthz.members_source
      AccountAuthz.members_source = source

      begin
        RemoveMember.new(person: @manager, account: 1, values: { member_id: "pretend-code" }).call
      ensure
        AccountAuthz.members_source = was
      end

      assert_nil @person.reload.account_id
    end
  end
end
