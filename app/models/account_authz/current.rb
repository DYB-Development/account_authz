# frozen_string_literal: true

module AccountAuthz
  class Current < ActiveSupport::CurrentAttributes
    attribute :account_id
  end
end
