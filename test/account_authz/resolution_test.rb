# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class ResolutionTest < Minitest::Test
    def test_can_is_true_when_the_grants_include_the_capability
      assert AccountAuthz.can?(%i[view_fulfillment revenue], :view_fulfillment)
    end

    def test_capabilities_are_the_declared_catalog_capabilities
      AccountAuthz.reset!
      AccountAuthz.catalog do
        permission :view_fulfillment
        metric :revenue
      end

      assert_equal %i[view_fulfillment revenue], AccountAuthz.capabilities
    ensure
      AccountAuthz.reset!
    end

    def test_approved_metrics_are_the_granted_catalog_metrics
      AccountAuthz.reset!
      AccountAuthz.catalog do
        permission :view_fulfillment
        metric :revenue
        metric :deals
      end

      assert_equal %i[revenue], AccountAuthz.approved_metrics(%i[view_fulfillment revenue])
    ensure
      AccountAuthz.reset!
    end
  end
end
