# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class TemplatesTest < Minitest::Test
    def test_declares_a_named_template_with_capabilities
      AccountAuthz.reset!
      AccountAuthz.templates do
        template :sales, capabilities: %w[revenue deals]
      end

      assert_equal %w[revenue deals], AccountAuthz.templates.find(:sales).capabilities
    ensure
      AccountAuthz.reset!
    end

    def test_defaults_returns_only_templates_flagged_default
      AccountAuthz.reset!
      AccountAuthz.templates do
        template :admin, capabilities: %w[revenue], default: true
        template :custom, capabilities: %w[revenue]
      end

      assert_equal %i[admin], AccountAuthz.templates.defaults.map(&:name)
    ensure
      AccountAuthz.reset!
    end
  end
end
