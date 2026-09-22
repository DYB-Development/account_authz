# frozen_string_literal: true

module AccountAuthz
  class Invite
    def initialize(person:, account:, values:)
      @person = person
      @account = AccountId.from(account)
      @values = values
    end

    def call
      AccountAuthz.members_source.invite(account_id: @account, invited_by: @person, name: @values[:name], email: @values[:email])

      Result.ok
    end
  end
end
