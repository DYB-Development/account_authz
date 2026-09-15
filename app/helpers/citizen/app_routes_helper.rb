module Citizen
  module AppRoutesHelper
    def method_missing(name, ...)
      app_route?(name) ? main_app.public_send(name, ...) : super
    end

    def respond_to_missing?(name, include_private = false)
      app_route?(name) || super
    end

    private

    def app_route?(name)
      name.end_with?("_path", "_url") && main_app.respond_to?(name)
    end
  end
end
