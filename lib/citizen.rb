# frozen_string_literal: true

require_relative "citizen/version"
require_relative "citizen/engine"
require_relative "citizen/catalog"
require_relative "citizen/templates"

module Citizen
  class Error < StandardError; end

  def self.catalog(&block)
    @catalog ||= Catalog.new
    @catalog.instance_eval(&block) if block
    @catalog
  end

  def self.templates(&block)
    @templates ||= Templates.new
    @templates.instance_eval(&block) if block
    @templates
  end

  def self.seed_default_roles(account_id)
    templates.defaults.reject { |template| Role.in_account(account_id).exists?(name: template.role_name) }
            .map { |template| Role.from_template(account_id: account_id, template: template.name) }
  end

  def self.reset!
    @catalog = nil
    @templates = nil
  end

  def self.capabilities
    catalog.capabilities
  end

  def self.can?(grants, capability)
    grants.include?(capability)
  end

  def self.approved_metrics(grants)
    catalog.metrics & grants
  end
end
