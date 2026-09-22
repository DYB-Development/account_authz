# frozen_string_literal: true

module AccountAuthz
  module AccountId
    def self.from(account)
      account.respond_to?(:id) ? account.id : account
    end
  end
end
