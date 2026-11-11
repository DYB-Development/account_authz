# frozen_string_literal: true

class LedgersController < ApplicationController
  include AccountAuthz::Authorization

  refuse_actions_without_a_permission
  requires_permission :revenue, only: :show

  def show
    render plain: "ledger"
  end

  def edit
    render plain: "editing"
  end
end
