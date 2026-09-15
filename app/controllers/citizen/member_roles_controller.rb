module Citizen
  class MemberRolesController < ApplicationController
    requires_capability { Citizen.members_capability }

    before_action { refuse(:member_out_of_reach) unless reach.includes_member?(member) }
    before_action { refuse(:role_out_of_reach) unless reach.includes_role?(role) }

    def create
      member.assign_role(role)

      redirect_to members_path
    end

    def destroy
      return refuse(:last_manager) if LastManager.new(account_id: Current.account_id).lost_by_taking?(member, role)

      member.revoke_role(role)

      redirect_to members_path
    end

    private

    def refuse(reason)
      redirect_to members_path, alert: t("citizen.refusals.#{reason}")
    end

    def reach
      @reach ||= Reach.new(current_member, account_id: Current.account_id)
    end

    def member
      @member ||= Citizen.members_source.members(Current.account_id).find(params[:member_id])
    end

    def role
      @role ||= Role.in_account(Current.account_id).find(params[:role_id] || params[:id])
    end
  end
end
