# frozen_string_literal: true

module Citizen
  module ActingMember
    def self.for(person:, account:, source: Citizen.members_source)
      return person unless source.respond_to?(:member_for)

      source.member_for(account_id: AccountId.from(account), person: person) || person
    end
  end
end
