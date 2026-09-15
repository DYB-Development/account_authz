Citizen::Engine.routes.draw do
  resources :members, only: :index do
    resources :roles, only: :create, controller: "member_roles"
  end
end
