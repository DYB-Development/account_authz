# frozen_string_literal: true

module Citizen
  class Invite
    def initialize(person:, account:, values:)
      @person = person
      @account = account
      @values = values
    end

    def call
      Citizen.members_source.invite(account_id: @account, invited_by: @person, name: @values[:name], email: @values[:email])

      Result.ok
    end
  end
end
