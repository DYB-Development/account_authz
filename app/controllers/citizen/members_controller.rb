module Citizen
  class MembersController < ApplicationController
    requires_capability { Citizen.members_capability }

    def index
      @members = Citizen.members_source.call(Current.account_id)
      @roles = Role.in_account(Current.account_id)
    end
  end
end
