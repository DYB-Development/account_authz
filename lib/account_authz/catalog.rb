# frozen_string_literal: true

module AccountAuthz
  class Catalog
    attr_reader :permissions, :metrics

    def initialize
      @permissions = []
      @metrics = []
    end

    def permission(key)
      @permissions << key
    end

    def metric(key)
      @metrics << key
    end

    def capabilities
      permissions + metrics
    end
  end
end
