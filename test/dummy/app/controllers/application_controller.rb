class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper Rails.application.routes.url_helpers

  before_action { AccountAuthz::Current.account_id = params[:account_id] }

  private

  def current_member
    ::Member.find_by(id: params[:signed_in_member_id])
  end
end
