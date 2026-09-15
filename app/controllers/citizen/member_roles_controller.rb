module Citizen
  class MemberRolesController < ApplicationController
    before_action { head :forbidden unless can?(Citizen.members_capability) }

    def create
      member.assign_role(role(params[:role_id]))

      redirect_to members_path
    end

    def destroy
      member.revoke_role(role(params[:id]))

      redirect_to members_path
    end

    private

    def member
      Citizen.members_source.call(Current.account_id).find(params[:member_id])
    end

    def role(id)
      Role.in_account(Current.account_id).find(id)
    end
  end
end
