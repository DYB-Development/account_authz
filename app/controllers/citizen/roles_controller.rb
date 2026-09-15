module Citizen
  class RolesController < ApplicationController
    requires_capability { Citizen.roles_capability }

    def index
      @roles = Role.in_account(Current.account_id)
    end

    def create
      if params[:template].present?
        Role.from_template(account_id: Current.account_id, template: params[:template].to_sym)
      else
        Role.create!(account_id: Current.account_id, **role_params)
      end

      redirect_to roles_path
    end

    private

    def role_params
      params.require(:role).permit(:name, capabilities: []).to_h.symbolize_keys
    end
  end
end
