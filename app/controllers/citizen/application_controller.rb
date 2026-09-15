module Citizen
  class ApplicationController < ::ApplicationController
    include Citizen::Authorization

    helper KeystoneUiHelper, Citizen::Engine.routes.url_helpers, Citizen::AppRoutesHelper

    before_action { Citizen::AppRoutesHelper.define_app_route_helpers }

    def self.requires_capability(&capability)
      before_action { head :forbidden unless can?(capability.call) }
    end

    private

    def refuse(reason, back_to:)
      redirect_to back_to, alert: t("citizen.refusals.#{reason}")
    end
  end
end
