Citizen::Engine.routes.draw do
  resources :members, only: :index
end
