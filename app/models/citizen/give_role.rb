# frozen_string_literal: true

module Citizen
  class GiveRole
    def initialize(person:, account:, values:)
      @person = person
      @account = AccountId.from(account)
      @values = values
    end

    def call
      return Result.refused(:member_out_of_reach) unless reach.includes_member?(member)
      return Result.refused(:role_out_of_reach) unless reach.includes_role?(role)

      member.assign_role(role)

      Result.ok
    end

    private

    def reach
      @reach ||= Reach.new(@person, account_id: @account)
    end

    def member
      @member ||= Citizen.members_source.members(@account).find(@values[:member_id])
    end

    def role
      @role ||= Role.in_account(@account).find(@values[:role_id])
    end
  end
end
