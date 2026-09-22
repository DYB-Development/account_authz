# frozen_string_literal: true

module AccountAuthz
  class CancelInvitation
    def initialize(person:, account:, values:)
      @person = person
      @account = AccountId.from(account)
      @values = values
    end

    def call
      AccountAuthz.members_source.cancel_invitation(invitation)

      Result.ok
    end

    private

    def invitation
      AccountAuthz.members_source.invitations(@account).find(@values[:invitation_id])
    end
  end
end
