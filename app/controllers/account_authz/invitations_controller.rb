module AccountAuthz
  class InvitationsController < ApplicationController
    requires_capability { AccountAuthz.members_capability }

    def new
    end

    def create
      run Invite, name: params.require(:invitation)[:name], email: params.require(:invitation)[:email]
    end

    def resend
      run ResendInvitation, invitation_id: params[:id]
    end

    def destroy
      run CancelInvitation, invitation_id: params[:id]
    end

    private

    def run(action, **values)
      result = action.new(person: current_member, account: Current.account_id, values: values).call

      return redirect_to(members_path, alert: result.message) unless result.ok?

      redirect_to members_path
    end
  end
end
