module Citizen
  class MembersController < ApplicationController
    before_action { head :forbidden unless can?(:manage_members) }

    def index
    end
  end
end
