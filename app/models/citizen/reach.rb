# frozen_string_literal: true

module Citizen
  class Reach
    def initialize(manager, account_id:)
      @manager = manager
      @account_id = account_id
    end

    def includes_member?(member)
      top_rank? || highest_rank(member) < own_rank
    end

    def includes_role?(role)
      top_rank? || role.rank < own_rank
    end

    def includes_capabilities?(capabilities)
      (Array(capabilities).map(&:to_sym) - @manager.capabilities(account_id: @account_id)).empty?
    end

    private

    def top_rank?
      own_rank.finite? && own_rank >= Role.in_account(@account_id).maximum(:rank)
    end

    def own_rank
      @own_rank ||= highest_rank(@manager)
    end

    def highest_rank(member)
      member.citizen_roles.in_account(@account_id).maximum(:rank) || -Float::INFINITY
    end
  end
end
