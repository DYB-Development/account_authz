module Citizen
  class RolesController < ApplicationController
    requires_capability { Citizen.roles_capability }

    def index
    end
  end
end
