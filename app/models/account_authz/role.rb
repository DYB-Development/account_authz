# frozen_string_literal: true

module AccountAuthz
  class Role < ApplicationRecord
    validates :name, presence: true
    validate :capabilities_within_catalog

    scope :in_account, ->(account_id) { where(account_id: account_id) }

    def self.from_template(account_id:, template:)
      definition = AccountAuthz.templates.find(template)
      create!(account_id: account_id, name: definition.role_name, capabilities: definition.capabilities)
    end

    private

    def capabilities_within_catalog
      known = AccountAuthz.capabilities.map(&:to_s)
      (Array(capabilities).map(&:to_s) - known).each do |unknown|
        errors.add(:capabilities, "includes unknown capability: #{unknown}")
      end
    end
  end
end
