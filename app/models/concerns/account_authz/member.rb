# frozen_string_literal: true

module AccountAuthz
  module Member
    extend ActiveSupport::Concern

    included do
      has_many :account_authz_assignments, as: :member, class_name: "AccountAuthz::Assignment", dependent: :destroy
      has_many :account_authz_roles, through: :account_authz_assignments, source: :role
    end

    def assign_role(role)
      account_authz_assignments.find_or_create_by(role: role)
    end

    def revoke_role(role)
      account_authz_assignments.where(role: role).destroy_all
    end

    def capabilities(account_id: nil)
      roles = account_id ? account_authz_roles.where(account_id: account_id) : account_authz_roles
      roles.flat_map(&:capabilities).uniq.map(&:to_sym)
    end

    def can?(capability, account_id: nil)
      AccountAuthz.can?(capabilities(account_id: account_id), capability)
    end

    def approved_metrics(account_id: nil)
      AccountAuthz.approved_metrics(capabilities(account_id: account_id))
    end
  end
end
