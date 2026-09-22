# frozen_string_literal: true

require "pundit"

module AccountAuthz
  module Authorization
    extend ActiveSupport::Concern

    included do
      include Pundit::Authorization
      helper_method :can?
    end

    def can?(capability)
      Current.account_id.present? && current_member&.can?(capability, account_id: Current.account_id) || false
    end
  end
end
