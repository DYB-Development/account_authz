# frozen_string_literal: true

require "test_helper"

module AccountAuthz
  class CatalogTest < Minitest::Test
    def test_records_a_permission
      catalog = Catalog.new
      catalog.permission(:view_fulfillment)

      assert_includes catalog.permissions, :view_fulfillment
    end

    def test_records_a_metric
      catalog = Catalog.new
      catalog.metric(:revenue)

      assert_includes catalog.metrics, :revenue
    end

    def test_capabilities_combine_permissions_and_metrics
      catalog = Catalog.new
      catalog.permission(:view_fulfillment)
      catalog.metric(:revenue)

      assert_equal %i[view_fulfillment revenue], catalog.capabilities
    end

    def test_global_catalog_dsl_declares_capabilities
      AccountAuthz.reset!
      AccountAuthz.catalog do
        permission :view_fulfillment
        metric :revenue
      end

      assert_equal %i[view_fulfillment revenue], AccountAuthz.catalog.capabilities
    ensure
      AccountAuthz.reset!
    end
  end
end
