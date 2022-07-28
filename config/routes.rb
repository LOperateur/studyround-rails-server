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
    resources :questions, only: [:index]
    resources :reviews
  end

  resources :questions do
    get '/explanation', to: "questions#explanation"
  end

  get 'dashboard/carousel'

  get '/user/results', to: "results#recent"
  get 'results/grouped', to: "results#grouped"
  get '/tests/:course_id/submissions', to: "results#test_submissions"
  resources :results, only: [:show] do
    get '/session-items', to: "results#session_items"
  end

  get '/sessions/consolidate', to: "sessions#submit_stale_sessions"
  get '/tests/:course_id/instructions', to: "sessions#test_instructions"
  get '/sessions/:id/verify', to: "sessions#verify_active_session"
  get '/tests/:course_id/verify', to: "sessions#verify_active_test"

  post '/sessions/:course_id/start', to: "sessions#start"
  post '/tests/:course_id/start', to: "sessions#start_test"
  post '/sessions/:course_id/end', to: "sessions#end"
  post '/tests/:course_id/end', to: "sessions#end_test"
  resources :sessions, only: [:update]

end
