Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :subscriptions, only: [ :create, :show ]

      namespace :apple do
        resources :webhooks, only: [ :create ]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
