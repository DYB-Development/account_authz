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
        return refuse(:capabilities_out_of_reach, back_to: new_role_path) unless reach.includes_capabilities?(role_params[:capabilities])

        Role.create!(account_id: Current.account_id, **role_params)
      end

      redirect_to roles_path
    end

    def edit
      @role = Role.in_account(Current.account_id).find(params[:id])
    end

    def update
      role = Role.in_account(Current.account_id).find(params[:id])
      return refuse(:rank_out_of_reach, back_to: edit_role_path(role)) if role_params.key?(:rank) && !reach.includes_rank?(role_params[:rank])
      return refuse(:capabilities_out_of_reach, back_to: edit_role_path(role)) unless reach.includes_capabilities?(Array(role_params[:capabilities]) - role.capabilities)
      return refuse(:last_manager, back_to: edit_role_path(role)) if role_params.key?(:capabilities) && LastManager.new(account_id: Current.account_id).lost_by_changing?(role, role_params[:capabilities])

      role.update!(**role_params)

      redirect_to roles_path
    end

    private

    def reach
      @reach ||= Reach.new(current_member, account_id: Current.account_id)
    end

    def role_params
      permitted = params.require(:role).permit(:name, :rank, capabilities: []).to_h.symbolize_keys
      permitted[:capabilities] = permitted[:capabilities].compact_blank if permitted.key?(:capabilities)
      permitted
    end
  end
end
