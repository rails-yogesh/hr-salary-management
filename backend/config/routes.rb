Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      post "login", to: "sessions#create"
      get "lookups", to: "lookups#index"

      resources :employees, only: %i[index show create update] do
        member do
          patch :terminate
        end
        resources :compensation_records, only: %i[create]
      end

      get "dashboard/summary", to: "dashboard#summary"
      get "dashboard/by_country", to: "dashboard#by_country"
      get "dashboard/by_department", to: "dashboard#by_department"
      get "dashboard/salary_distribution", to: "dashboard#salary_distribution"
    end
  end
end
