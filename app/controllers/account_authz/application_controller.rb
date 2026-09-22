module AccountAuthz
  class ApplicationController < ::ApplicationController
    include AccountAuthz::Authorization

    helper KeystoneUiHelper, AccountAuthz::Engine.routes.url_helpers, AccountAuthz::AppRoutesHelper

    before_action { AccountAuthz::AppRoutesHelper.define_app_route_helpers }

    def self.requires_capability(&capability)
      before_action { head :forbidden unless can?(capability.call) }
    end

    private

    def refuse(reason, back_to:)
      redirect_to back_to, alert: t("account_authz.refusals.#{reason}")
    end
  end
end
