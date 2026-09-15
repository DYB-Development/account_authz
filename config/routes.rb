Citizen::Engine.routes.draw do
  resources :members, only: :index do
    resources :roles, only: [ :create, :destroy ], controller: "member_roles"
  end
  resources :roles, only: [ :index, :create, :update ]
end
