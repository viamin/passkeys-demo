Rails.application.routes.draw do
  get "users/settings"
  resource :session
  resources :passwords, param: :token

  resources :passkeys, only: %i[ create destroy ] do
    post :challenge, on: :collection
    # collection do
    #   resource :challenge, only: %i[create], module: :passkeys, as: :passkeys_challenge
    # end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "sessions#new"
end
