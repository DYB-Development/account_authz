# frozen_string_literal: true

require "test_helper"

module Citizen
  class ApplicationPolicyTest < ActiveSupport::TestCase
    StubMember = Struct.new(:granted) do
      def can?(capability, account_id: nil)
        granted.include?(capability)
      end
    end

    test "can? delegates the capability check to the member" do
      policy = ApplicationPolicy.new(StubMember.new(%i[revenue]), :report)

      assert policy.can?(:revenue)
    end

    test "a capability held only in another account is denied" do
      Citizen.reset!
      Citizen.catalog { metric :revenue }
      member = ::Member.create!
      member.assign_role(Role.create!(account_id: 1, name: "Sales", capabilities: %w[revenue]))
      Current.account_id = 2

      assert_not ApplicationPolicy.new(member, :report).can?(:revenue)
    ensure
      Citizen.reset!
      Current.reset
    end
  end
end
