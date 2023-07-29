Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root to: 'weather#new'
  resources :weather, only: [:new, :create]
  get 'weather/show/:zip', to: 'weather#show', as: 'show_weather'
end
