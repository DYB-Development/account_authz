Citizen::Engine.routes.draw do
  resources :members, only: :index do
    resources :roles, only: [ :create, :destroy ], controller: "member_roles"
  end
  resources :roles, only: [ :index, :new, :create, :edit, :update ]
  resources :invitations, only: :create
end
