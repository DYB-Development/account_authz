module AccountAuthz
  class MembersController < ApplicationController
    requires_capability { AccountAuthz.members_capability }

    def index
      @members = AccountAuthz.members_source.members(Current.account_id)
      @held_roles = held_roles
      @invitations = AccountAuthz.members_source.invitations(Current.account_id)
    end

    def show
      @member = AccountAuthz.members_source.members(Current.account_id).find(params[:id])
      @held = Assignment.where(member: @member, role: Role.in_account(Current.account_id)).includes(:role).map(&:role)
      @reach = reach
      @last_manager = LastManager.new(account_id: Current.account_id)
      @roles = Role.in_account(Current.account_id).select { |role| reach.includes_role?(role) }
    end

    def destroy
      result = RemoveMember.new(person: current_member, account: Current.account_id, values: { member_id: params[:id] }).call

      return redirect_to(members_path, alert: result.message) unless result.ok?

      redirect_to members_path
    end

    private

    def held_roles
      Assignment.where(member: @members.to_a, role: Role.in_account(Current.account_id)).includes(:role)
        .group_by(&:member_id).transform_values { |assignments| assignments.map(&:role) }
    end

    def reach
      @reach ||= Reach.new(current_member, account_id: Current.account_id)
    end
  end
end
