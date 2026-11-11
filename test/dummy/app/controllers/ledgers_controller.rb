# frozen_string_literal: true

class LedgersController < ApplicationController
  include AccountAuthz::Authorization

  refuse_actions_without_a_permission
  requires_permission :revenue, only: :show
  open_to_every_member only: :index, reason: "Every member reads the list of ledgers."

  def index
    render plain: "ledgers"
  end

  def show
    render plain: "ledger"
  end

  def edit
    render plain: "editing"
  end
end
