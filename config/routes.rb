Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resources :transactions, except: [:show]
  resources :goals, except: [:show] do
    resources :contributions, only: [:new, :create, :destroy], controller: "goal_contributions"
  end

  resources :contributions, only: [:new, :create], controller: "goal_contributions"
  resources :goal_transfers, only: [:new, :create]

  get  "budget", to: "budget#allocate"
  get  "budget/calendar", to: "budget#calendar"
  patch "budget", to: "budget#update_allocations"

  resources :notifications, only: [:index, :show] do
    post :read_all, on: :collection
  end

  get "reports", to: "reports#index"
  get    "settings",                to: "settings#edit"
  patch  "settings/profile",        to: "settings#update_profile",  as: :settings_profile
  patch  "settings/password",       to: "settings#update_password", as: :settings_password
  patch  "settings/notifications",  to: "settings#update_notifications", as: :settings_notifications
  get    "settings/delete_account", to: "settings#confirm_delete",  as: :confirm_delete_account
  delete "settings/avatar",         to: "settings#destroy_avatar",  as: :settings_avatar
  delete "settings/account",        to: "settings#destroy_account", as: :settings_account
  resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
