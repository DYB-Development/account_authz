module Citizen
  class MemberRolesController < ApplicationController
    requires_capability { Citizen.members_capability }

    def create
      role = role(params[:role_id])
      return head :forbidden unless reach.includes_role?(role)

      member.assign_role(role)

      redirect_to members_path
    end

    def destroy
      member.revoke_role(role(params[:id]))

      redirect_to members_path
    end

    private

    def reach
      Reach.new(current_member, account_id: Current.account_id)
    end

    def member
      Citizen.members_source.call(Current.account_id).find(params[:member_id])
    end

    def role(id)
      Role.in_account(Current.account_id).find(id)
    end
  end
end
