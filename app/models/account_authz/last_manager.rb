# frozen_string_literal: true

module AccountAuthz
  class LastManager
    def initialize(account_id:)
      @account_id = account_id
    end

    def lost_by_taking?(member, role)
      managing_assignments.none? { |assignment| !holds?(assignment, member, role) }
    end

    def lost_by_removing?(member)
      managing_assignments.none? { |assignment| !held_by?(assignment, member) }
    end

    def lost_by_changing?(role, capabilities)
      managing_role_ids.include?(role.id) && !grants_members_capability?(capabilities) && managing_assignments.none? { |assignment| assignment.role_id != role.id }
    end

    private

    def managing_assignments
      @managing_assignments ||= Assignment.where(role_id: managing_role_ids).to_a
    end

    def holds?(assignment, member, role)
      held_by?(assignment, member) && assignment.role_id == role.id
    end

    def held_by?(assignment, member)
      assignment.member_id == member.id && assignment.member_type == member.class.polymorphic_name
    end

    def managing_role_ids
      @managing_role_ids ||= Role.in_account(@account_id).select { |role| grants_members_capability?(role.capabilities) }.map(&:id)
    end

    def grants_members_capability?(capabilities)
      AccountAuthz.can?(Array(capabilities).map(&:to_sym), AccountAuthz.members_capability)
    end
  end
end
