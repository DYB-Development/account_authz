# frozen_string_literal: true

module Citizen
  class LastManager
    def initialize(account_id:)
      @account_id = account_id
    end

    def lost_by_taking?(member, role)
      managing_assignments.where.not(member: member, role: role).none?
    end

    def lost_by_removing?(member)
      managing_assignments.where.not(member: member).none?
    end

    def lost_by_changing?(role, capabilities)
      managing_role_ids.include?(role.id) && !grants_members_capability?(capabilities) && managing_assignments.where.not(role: role).none?
    end

    private

    def managing_assignments
      Assignment.where(role_id: managing_role_ids)
    end

    def managing_role_ids
      @managing_role_ids ||= Role.in_account(@account_id).select { |role| grants_members_capability?(role.capabilities) }.map(&:id)
    end

    def grants_members_capability?(capabilities)
      Citizen.can?(Array(capabilities).map(&:to_sym), Citizen.members_capability)
    end
  end
end
