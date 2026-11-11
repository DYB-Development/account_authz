Rails.application.routes.draw do
  mount AccountAuthz::Engine => "/account_authz"

  get "reports" => "reports#show"
  get "ledger" => "ledgers#show"
  get "ledger/edit" => "ledgers#edit"
end
