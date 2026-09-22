# frozen_string_literal: true

module AccountAuthz
  # Single source of truth for account_authz's user-facing API, read by the
  # the_local companion subagents so their guidance never drifts from the docs.
  module Reference
    DIR = File.expand_path("reference", __dir__)

    def self.content
      read("guide.md")
    end

    def self.read(name)
      File.read(File.join(DIR, name)).chomp
    end
  end
end
