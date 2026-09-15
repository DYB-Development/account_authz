module Citizen
  class MemberRolesController < ApplicationController
    before_action { head :forbidden unless can?(Citizen.members_capability) }

    def create
      member = Citizen.members_source.call(Current.account_id).find(params[:member_id])
      member.assign_role(Role.find(params[:role_id]))

      redirect_to members_path
    end
  end
end
