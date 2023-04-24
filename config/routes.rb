require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/health-check', to: "health_check#index"

  mount Sidekiq::Web => '/sidekiq'
  post '/auth/signup', to: "auth#signup"
  post '/auth/login', to: "auth#login"
  post '/auth/support/login', to: "auth#login_content_support"
  post '/auth/reset', to: "auth#reset"
  post '/auth/refresh-token', to: "auth#refresh_token"
  post '/otp/generate', to: "auth#generate_otp"
  post '/otp/validate', to: "auth#validate_otp"

  get '/user', to: "users#profile"
  put '/user', to: "users#update"
  get '/user/interests', to: "users#interested_categories"
  post '/user/interests', to: "users#create_interests"
  resources :users, only: [:show]
  get '/admin/users', to: "users#admin_index"
  post '/admin/assign-course', to: "users#assign_course"

  resources :categories, only: [:index, :show, :create, :update, :destroy] do
    get '/courses', to: "courses#per_category"
  end

  get '/courses/categorised', to: "courses#categorised"
  get '/courses/top', to: "courses#top_courses"
  get '/courses/trending', to: "courses#trending_courses"
  get '/courses/recent', to: "courses#recent_courses"
  get '/courses/my-courses', to: "courses#my_courses"
  get '/courses/tests', to: "courses#tests"
  get '/courses/created', to: "courses#created_courses"
  get '/courses/tests/created', to: "courses#created_tests"
  get '/courses/purchased', to: "courses#purchased_courses"
  get '/courses/tests/purchased', to: "courses#purchased_tests"
  get '/search', to: "courses#search"
  patch '/courses/:id/publish', to: "courses#publish"
  post '/courses/:id/purchase', to: "courses#purchase"
  resources :courses, only: [:index, :show, :create, :update, :destroy] do
    resources :questions, only: [:index]
    resources :reviews
  end

  get '/creator/courses/:course_id/questions', to: "questions#questions"
  post '/creator/courses/:course_id/questions', to: "questions#create"
  get '/creator/courses/:course_id/questions/:id', to: "questions#show"
  put '/creator/courses/:course_id/questions/:id', to: "questions#update"
  patch '/creator/courses/:course_id/questions/:id/publish', to: "questions#publish"
  delete '/creator/courses/:course_id/questions/:id', to: "questions#destroy"

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

  get '/tests/:course_id/instructions', to: "sessions#test_instructions"
  get '/sessions/:id/verify', to: "sessions#verify_active_session"

  post '/sessions/:course_id/start', to: "sessions#start"
  post '/sessions/:course_id/start-demo', to: "sessions#start_demo"
  post '/tests/:course_id/start', to: "sessions#start_test"
  post '/sessions/:course_id/end', to: "sessions#end"
  post '/sessions/:course_id/end-demo', to: "sessions#end_demo"
  post '/tests/:course_id/end', to: "sessions#end_test"
  post '/tests/:course_id/complete', to: "courses#close_test"
  resources :sessions, only: [:update]

  get '/transactions/initiate', to: "transactions#initiate"
  post '/transactions/verify', to: "transactions#verify"
  post '/transactions/process', to: "transactions#process_transaction"

  resources :cards, only: [:index, :destroy]

  resources :guests, only: [:create] do
    post '/invite', to: "guests#invite"
  end

  get '/faqs', to: "faqs#index"

  # Route for root endpoint
  root to: "health_check#index", via: :all

  # Catch all route for not-found endpoints
  match '*path', to: "application#endpoint_not_found", via: :all
end
