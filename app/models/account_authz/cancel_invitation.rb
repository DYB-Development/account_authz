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
      AccountAuthz.find_invitation(@account, @values[:invitation_id])
    end
  end
end
