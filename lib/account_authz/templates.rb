# frozen_string_literal: true

module AccountAuthz
  class Templates
    Template = Struct.new(:name, :capabilities, :default, keyword_init: true) do
      def role_name
        name.to_s.titleize
      end
    end

    def initialize
      @templates = []
    end

    def template(name, capabilities:, default: false)
      @templates << Template.new(name: name, capabilities: capabilities, default: default)
    end

    def find(name)
      @templates.find { |template| template.name == name }
    end

    def defaults
      @templates.select(&:default)
    end
  end
end
