# frozen_string_literal: true

module AccountAuthz
  class Reach
    def initialize(manager, account_id:)
      @manager = manager
      @account_id = account_id
    end

    def includes_member?(member)
      includes_roles?(member.account_authz_roles.in_account(@account_id))
    end

    def includes_roles?(roles)
      top_rank? || (roles.map(&:rank).max || -Float::INFINITY) < own_rank
    end

    def includes_role?(role)
      top_rank? || role.rank < own_rank
    end

    def includes_capabilities?(capabilities)
      (Array(capabilities).map(&:to_sym) - @manager.capabilities(account_id: @account_id)).empty?
    end

    def includes_rank?(rank)
      rank.to_i <= own_rank
    end

    private

    def top_rank?
      return @top_rank unless @top_rank.nil?

      @top_rank = own_rank.finite? && own_rank >= Role.in_account(@account_id).maximum(:rank)
    end

    def own_rank
      @own_rank ||= highest_rank(@manager)
    end

    def highest_rank(member)
      member.account_authz_roles.in_account(@account_id).maximum(:rank) || -Float::INFINITY
    end
  end
end
