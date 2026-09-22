# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class ApplicationPolicyTest < ActiveSupport::TestCase
    StubMember = Struct.new(:granted) do
      def can?(capability, account_id: nil)
        granted.include?(capability)
      end
    end

    test "can? delegates the capability check to the member" do
      Current.account_id = 1
      policy = ApplicationPolicy.new(StubMember.new(%i[revenue]), :report)

      assert policy.can?(:revenue)
    ensure
      Current.reset
    end

    test "a capability held only in another account is denied" do
      AccountAuthz.reset!
      AccountAuthz.catalog { metric :revenue }
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))
      Current.account_id = 2

      assert_not ApplicationPolicy.new(member, :report).can?(:revenue)
    ensure
      AccountAuthz.reset!
      Current.reset
    end

    test "a capability is denied when no current account is set" do
      AccountAuthz.reset!
      AccountAuthz.catalog { metric :revenue }
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))

      assert_not ApplicationPolicy.new(member, :report).can?(:revenue)
    ensure
      AccountAuthz.reset!
      Current.reset
    end
  end
end
