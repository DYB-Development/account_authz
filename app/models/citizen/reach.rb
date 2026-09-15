# frozen_string_literal: true

module Citizen
  class Reach
    def initialize(manager, account_id:)
      @manager = manager
      @account_id = account_id
    end

    def includes_member?(member)
      highest_rank(member) < highest_rank(@manager)
    end

    private

    def highest_rank(member)
      member.citizen_roles.in_account(@account_id).maximum(:rank)
    end
  end
end
