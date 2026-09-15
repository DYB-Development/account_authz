module Citizen
  class MembersController < ApplicationController
    requires_capability { Citizen.members_capability }

    def index
      @members = Citizen.members_source.members(Current.account_id)
      @reach = Reach.new(current_member, account_id: Current.account_id)
      @roles = Role.in_account(Current.account_id).select { |role| @reach.includes_role?(role) }
    end

    def destroy
      member = Citizen.members_source.members(Current.account_id).find(params[:id])
      Citizen.members_source.remove(member)

      redirect_to members_path
    end
  end
end
