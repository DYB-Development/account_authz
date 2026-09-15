module Citizen
  class RolesController < ApplicationController
    before_action { head :forbidden unless can?(:manage_roles) }

    def index
    end
  end
end
