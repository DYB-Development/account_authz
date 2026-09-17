module Citizen
  class InvitationsController < ApplicationController
    requires_capability { Citizen.members_capability }

    def new
    end

    def create
      Citizen.members_source.invite(account_id: Current.account_id, invited_by: current_member, **invitation_params)

      redirect_to members_path
    end

    def resend
      Citizen.members_source.resend_invitation(invitation)

      redirect_to members_path
    end

    def destroy
      Citizen.members_source.cancel_invitation(invitation)

      redirect_to members_path
    end

    private

    def invitation
      Citizen.members_source.invitations(Current.account_id).find(params[:id])
    end

    def invitation_params
      params.require(:invitation).permit(:name, :email).to_h.symbolize_keys
    end
  end
end
