module Citizen
  class MembersController < ApplicationController
    requires_capability { Citizen.members_capability }

    def index
      @members = Citizen.members_source.members(Current.account_id)
      @reach = reach
      @last_manager = LastManager.new(account_id: Current.account_id)
      @roles = Role.in_account(Current.account_id).select { |role| reach.includes_role?(role) }
    end

    def destroy
      member = Citizen.members_source.members(Current.account_id).find(params[:id])
      return refuse(:member_out_of_reach, back_to: members_path) unless reach.includes_member?(member)
      return refuse(:not_removable, back_to: members_path) unless Citizen.members_source.removable?(member)
      return refuse(:last_manager, back_to: members_path) if LastManager.new(account_id: Current.account_id).lost_by_removing?(member)

      ApplicationRecord.transaction do
        member.citizen_roles.in_account(Current.account_id).each { |role| member.revoke_role(role) }
        Citizen.members_source.remove(member)
      end

      redirect_to members_path
    end

    private

    def reach
      @reach ||= Reach.new(current_member, account_id: Current.account_id)
    end
  end
end
