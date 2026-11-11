Rails.application.routes.draw do
  mount AccountAuthz::Engine => "/account_authz"

  get "reports" => "reports#show"
  get "ledgers" => "ledgers#index"
  get "ledger" => "ledgers#show"
  get "hidden_ledger" => "hidden_ledgers#show"
  get "ledger/edit" => "ledgers#edit"
end
