# frozen_string_literal: true

require "test_helper"

module Citizen
  class RolesPageTest < ActionDispatch::IntegrationTest
    setup do
      Citizen.reset!
      Citizen.catalog do
        permission :manage_roles
        permission :view_reports
      end
      @admin = ::Member.create!(account_id: 1, name: "Pretend Admin")
      @admin.assign_role(Role.create!(account_id: 1, name: "Admin", capabilities: %w[manage_roles]))
    end

    teardown { Citizen.reset! }

    test "a member who can manage roles opens the roles page" do
      get "/citizen/roles", params: { signed_in_member_id: @admin.id, account_id: 1 }

      assert_response :success
    end
  end
end
