# frozen_string_literal: true

class HiddenLedgersController < LedgersController
  private

  def refuse_the_action
    head :not_found
  end
end
