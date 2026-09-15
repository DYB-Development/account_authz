module Citizen
  class RolesController < ApplicationController
    requires_capability { Citizen.roles_capability }

    def index
      @roles = Role.in_account(Current.account_id)
    end
  end
end
