# frozen_string_literal: true

module Citizen
  class CancelInvitation
    def initialize(person:, account:, values:)
      @person = person
      @account = account
      @values = values
    end

    def call
      Citizen.members_source.cancel_invitation(invitation)

      Result.ok
    end

    private

    def invitation
      Citizen.members_source.invitations(@account).find(@values[:invitation_id])
    end
  end
end
