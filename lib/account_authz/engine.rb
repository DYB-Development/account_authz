require "keystone_ui"

module AccountAuthz
  class Engine < ::Rails::Engine
    isolate_namespace AccountAuthz
  end
end
