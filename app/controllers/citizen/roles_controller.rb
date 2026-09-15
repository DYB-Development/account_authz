module Citizen
  class RolesController < ApplicationController
    requires_capability { Citizen.roles_capability }

    def index
      @roles = Role.in_account(Current.account_id)
    end

    def new
      @role = Role.new(account_id: Current.account_id)
    end

    def create
      if params[:template].present?
        Role.from_template(account_id: Current.account_id, template: params[:template].to_sym)
      else
        Role.create!(account_id: Current.account_id, **role_params)
      end

      redirect_to roles_path
    end

    def update
      Role.in_account(Current.account_id).find(params[:id]).update!(**role_params)

      redirect_to roles_path
    end

    private

    def role_params
      permitted = params.require(:role).permit(:name, capabilities: []).to_h.symbolize_keys
      permitted[:capabilities] = permitted[:capabilities].compact_blank if permitted.key?(:capabilities)
      permitted
    end
  end
end
