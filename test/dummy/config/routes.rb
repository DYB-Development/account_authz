Rails.application.routes.draw do
  mount AccountAuthz::Engine => "/account_authz"

  get "reports" => "reports#show"
end
