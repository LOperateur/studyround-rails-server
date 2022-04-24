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
  get '/user/interests', to: "users#interested_categories"
  post '/user/interests', to: "users#create_interests"

  resources :categories, only: [:index] do
    get '/courses', to: "courses#per_category"
  end

  get '/courses/categorised', to: "courses#categorised"
  get '/courses/top', to: "courses#top_courses"
  get '/courses/recent', to: "courses#recent_courses"
  get '/search', to: "courses#search"
  resources :courses, only: [:index, :show] do
    resources :reviews
  end

  get 'dashboard/carousel'

  get '/user/results', to: "results#recent"
end
