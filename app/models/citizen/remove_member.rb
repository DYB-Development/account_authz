# frozen_string_literal: true

module Citizen
  class RemoveMember
    def initialize(person:, account:, values:)
      @person = person
      @account = account
      @values = values
    end

    def call
      return Result.refused(:member_out_of_reach) unless reach.includes_member?(member)
      return Result.refused(:not_removable) unless Citizen.members_source.removable?(member)
      return Result.refused(:last_manager) if LastManager.new(account_id: @account).lost_by_removing?(member)

      ApplicationRecord.transaction do
        member.citizen_roles.in_account(@account).each { |role| member.revoke_role(role) }
        Citizen.members_source.remove(member)
      end

      Result.ok
    end

    private

    def reach
      @reach ||= Reach.new(@person, account_id: @account)
    end

    def member
      @member ||= Citizen.members_source.members(@account).find(@values[:member_id])
    end
  end
end
