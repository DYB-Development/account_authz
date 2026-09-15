module Citizen
  class RolesController < ApplicationController
    before_action { head :forbidden unless can?(Citizen.roles_capability) }

    def index
    end
  end
end
