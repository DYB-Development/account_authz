# frozen_string_literal: true

module AccountAuthz
  class Result
    attr_reader :message

    def self.ok
      new(ok: true)
    end

    def self.refused(reason)
      new(ok: false, message: I18n.t("account_authz.refusals.#{reason}"))
    end

    def initialize(ok:, message: nil)
      @ok = ok
      @message = message
    end

    def ok?
      @ok
    end
  end
end
