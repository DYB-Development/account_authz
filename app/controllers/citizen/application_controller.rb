module Citizen
  class ApplicationController < ::ApplicationController
    include Citizen::Authorization

    helper Citizen::AppRoutesHelper, KeystoneUiHelper

    def self.requires_capability(&capability)
      before_action { head :forbidden unless can?(capability.call) }
    end
  end
end
