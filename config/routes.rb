Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post 'auth/signup'
  post 'auth/login'
  post 'auth/reset'
  post '/auth/refresh-token', to: "auth#refresh_token"
  post '/otp/generate', to: "auth#generate_otp"
  post '/otp/validate', to: "auth#validate_otp"

  resources :users, only: [:show]
  get '/user', to: "users#profile"
  get '/user/categories', to: "users#interested_categories"
  post '/user/interests', to: "users#create_interests"

  resources :categories, only: [:index]

  resources :courses, only: [:index] do
    post '/categories', to: "courses#categorised"
    post '/interest', to: "courses#interest_categorised"
  end
end
