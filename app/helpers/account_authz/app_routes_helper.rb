module AccountAuthz
  module AppRoutesHelper
    def self.define_app_route_helpers
      @app_route_helpers_defined ||= begin
        (Rails.application.routes.named_routes.helper_names - AccountAuthz::Engine.routes.named_routes.helper_names).each do |name|
          define_method(name) { |*args, **options| main_app.public_send(name, *args, **options) }
        end
        true
      end
    end
  end
end
