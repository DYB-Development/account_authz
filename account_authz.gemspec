# frozen_string_literal: true

require_relative "lib/account_authz/version"

Gem::Specification.new do |spec|
  spec.name = "account_authz"
  spec.version = AccountAuthz::VERSION
  spec.authors = [ "tylercschneider" ]
  spec.email = [ "tylercschneider@gmail.com" ]

  spec.summary = "Capability-based authorization: roles grant capabilities, Pundit enforces"
  spec.description = "AccountAuthz is the authorization layer for multi-tenant apps. The app declares a " \
    "fixed catalog of capabilities (permission + metric keys) in code; accounts manage roles as data " \
    "that bundle those capabilities; AccountAuthz resolves what a member may do (can?) and which metrics " \
    "they may see (approved_metrics) from their roles, and plugs into Pundit for enforcement."
  spec.homepage = "https://github.com/DYB-Development/account_authz"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,the_local}/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  end
  # json 3 dropped the second argument ActiveSupport::JSON.decode passes it, so
  # every read of the capabilities column raises until Rails ships a release
  # that calls the new interface.
  spec.add_dependency "json", "< 3"


  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "pundit", ">= 2.0"
  spec.add_dependency "keystone_ui", ">= 0.9"
end
