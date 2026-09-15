# frozen_string_literal: true

module Citizen
  class LastManager
    def initialize(account_id:)
      @account_id = account_id
    end

    def lost_by_taking?(member, role)
      true
    end
  end
end
