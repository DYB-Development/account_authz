# frozen_string_literal: true

require "pundit"

module AccountAuthz
  module Authorization
    extend ActiveSupport::Concern

    EVERY_MEMBER = :every_member

    included do
      include Pundit::Authorization
      helper_method :can?
      class_attribute :action_permissions, instance_writer: false, default: {}
    end

    class_methods do
      def refuse_actions_without_a_permission
        before_action :refuse_an_action_its_member_may_not_take
      end

      def requires_permission(capability, only:)
        self.action_permissions = action_permissions.merge(Array(only).to_h { |action| [action.to_s, capability] })
      end

      def open_to_every_member(only:, reason:)
        requires_permission(EVERY_MEMBER, only: only)
      end
    end

    def can?(capability)
      Current.account_id.present? && current_member&.can?(capability, account_id: Current.account_id) || false
    end

    private

    def refuse_an_action_its_member_may_not_take
      head :forbidden unless may_take_this_action?
    end

    def may_take_this_action?
      capability = action_permissions[action_name]
      return current_member.present? if capability == EVERY_MEMBER

      capability.present? && can?(capability)
    end
  end
end
