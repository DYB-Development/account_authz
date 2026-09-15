module Citizen
  class MembersController < ApplicationController
    before_action { head :forbidden unless can?(:manage_members) }

    def index
      @members = Citizen.members_source.call(Current.account_id)
    end
  end
end
