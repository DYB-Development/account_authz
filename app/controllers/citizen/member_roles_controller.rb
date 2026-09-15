module Citizen
  class MemberRolesController < ApplicationController
    requires_capability { Citizen.members_capability }

    before_action { head :forbidden unless reach.includes_member?(member) && reach.includes_role?(role) }

    def create
      member.assign_role(role)

      redirect_to members_path
    end

    def destroy
      member.revoke_role(role)

      redirect_to members_path
    end

    private

    def reach
      @reach ||= Reach.new(current_member, account_id: Current.account_id)
    end

    def member
      @member ||= Citizen.members_source.call(Current.account_id).find(params[:member_id])
    end

    def role
      @role ||= Role.in_account(Current.account_id).find(params[:role_id] || params[:id])
    end
  end
end
