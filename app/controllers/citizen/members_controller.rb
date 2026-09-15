module Citizen
  class MembersController < ApplicationController
    requires_capability { Citizen.members_capability }

    def index
      @members = Citizen.members_source.members(Current.account_id)
      @reach = reach
      @roles = Role.in_account(Current.account_id).select { |role| reach.includes_role?(role) }
    end

    def destroy
      member = Citizen.members_source.members(Current.account_id).find(params[:id])
      return head :forbidden unless reach.includes_member?(member) && Citizen.members_source.removable?(member)

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
