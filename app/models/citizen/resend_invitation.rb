# frozen_string_literal: true

module Citizen
  class ResendInvitation
    def initialize(person:, account:, values:)
      @person = person
      @account = account
      @values = values
    end

    def call
      Citizen.members_source.resend_invitation(invitation)

      Result.ok
    end

    private

    def invitation
      Citizen.members_source.invitations(@account).find(@values[:invitation_id])
    end
  end
end
