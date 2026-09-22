# frozen_string_literal: true

class ReportsController < ApplicationController
  include AccountAuthz::Authorization

  before_action { AccountAuthz::Current.account_id = params[:account_id] }

  def show
  end

  private

  def current_member
    Member.find(params[:member_id])
  end
end
