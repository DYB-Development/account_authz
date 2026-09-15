module Citizen
  class RolesController < ApplicationController
    requires_capability { Citizen.roles_capability }

    def index
      @roles = Role.in_account(Current.account_id)
    end

    def create
      Role.create!(account_id: Current.account_id, **role_params)

      redirect_to roles_path
    end

    private

    def role_params
      params.require(:role).permit(:name).to_h.symbolize_keys
    end
  end
end
