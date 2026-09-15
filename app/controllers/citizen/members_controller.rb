module Citizen
  class MembersController < ApplicationController
    before_action { head :forbidden unless can?(Citizen.members_capability) }

    def index
      @members = Citizen.members_source.call(Current.account_id)
    end
  end
end
