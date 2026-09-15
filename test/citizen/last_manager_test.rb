# frozen_string_literal: true

require "test_helper"

module Citizen
  class LastManagerTest < ActiveSupport::TestCase
    setup do
      Citizen.reset!
      Citizen.catalog { permission :manage_members }
      @manager_role = Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members])
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(@manager_role)
    end

    teardown { Citizen.reset! }

    test "taking the members role from the only member who holds it loses the last manager" do
      assert LastManager.new(account_id: 1).lost_by_taking?(@manager, @manager_role)
    end
  end
end
