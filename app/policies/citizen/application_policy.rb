# frozen_string_literal: true

module Citizen
  class ApplicationPolicy
    attr_reader :member, :record

    def initialize(member, record)
      @member = member
      @record = record
    end

    def can?(capability)
      Current.account_id.present? && member.can?(capability, account_id: Current.account_id)
    end
  end
end
