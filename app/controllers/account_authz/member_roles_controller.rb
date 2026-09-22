module AccountAuthz
  class MemberRolesController < ApplicationController
    requires_capability { AccountAuthz.members_capability }

    def create
      run GiveRole
    end

    def destroy
      run TakeRole
    end

    private

    def run(action)
      result = action.new(person: current_member, account: Current.account_id, values: submitted_values).call

      return redirect_to(members_path, alert: result.message) unless result.ok?

      redirect_to members_path
    end

    def submitted_values
      { member_id: params[:member_id], role_id: params[:role_id] || params[:id] }
    end
  end
end
