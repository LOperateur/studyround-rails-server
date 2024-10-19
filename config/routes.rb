require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/health-check', to: "health_check#index"

  mount Sidekiq::Web => '/sidekiq'
  post '/auth/signup', to: "auth#signup"
  post '/auth/login', to: "auth#login"
  get '/auth/google', to: "auth#google_oauth_web"
  post '/auth/google/mobile', to: "auth#google_oauth_mobile"
  post '/auth/support/login', to: "auth#login_creator"
  post '/auth/reset', to: "auth#reset"
  post '/auth/refresh-token', to: "auth#refresh_token"
  post '/otp/generate', to: "auth#generate_otp"
  post '/otp/validate', to: "auth#validate_otp"

  get '/user', to: "users#show_current_user"
  put '/user', to: "users#update"
  get '/user/interests', to: "users#interested_categories"
  post '/user/interests', to: "users#create_interests"
  patch '/user/onboard', to: "users#onboard"
  patch '/user/creator-consent', to: "users#creator_consent"
  resources :users, only: [:show]

  post '/categories/generate', to: "categories#generate_default_categories"
  resources :categories, only: [:index, :show, :create, :update, :destroy] do
    get '/courses', to: "courses#per_category"
  end

  get '/courses/categorised', to: "courses#categorised"
  get '/courses/top', to: "courses#top_courses"
  get '/courses/trending', to: "courses#trending_courses"
  get '/courses/recent', to: "courses#recent_courses"
  get '/courses/my-courses', to: "courses#my_courses"
  get '/courses/tests', to: "courses#tests"
  get '/courses/placeholder', to: "courses#dummy_courses"
  get '/courses/created', to: "courses#created_courses"
  get '/courses/enrolled', to: "courses#enrolled_courses"
  get '/courses/purchased', to: "courses#purchased_courses"
  get '/courses/tests/purchased', to: "courses#purchased_tests"
  get '/search', to: "courses#search"
  patch '/courses/:id/publish', to: "courses#publish"
  post '/courses/:id/purchase', to: "courses#purchase"
  post '/tests/:id/halt-attempts', to: "courses#halt_attempts"
  post '/tests/:id/complete', to: "courses#close_test"
  resources :courses, only: [:index, :show, :create, :update, :destroy] do
    get '/similar', to: "courses#similar_courses"
    post '/request-access', to: "collaborators#request_access"
    post '/grant-access', to: "collaborators#grant_access"
    resources :questions, only: [:index] do
      get '/', to: "questions#preview"
      get '/explanation', to: "questions#explanation"
    end
    resources :reviews
    resources :question_assets, only: [:index, :create, :update, :show, :destroy]
  end

  get '/creator/courses/:course_id/questions', to: "questions#questions"
  post '/creator/courses/:course_id/questions', to: "questions#create"
  post '/creator/courses/:course_id/questions/import', to: "questions#bulk_import_questions_json"
  get '/creator/courses/:course_id/questions/:id', to: "questions#show"
  put '/creator/courses/:course_id/questions/:id', to: "questions#update"
  patch '/creator/courses/:course_id/questions/:id/publish', to: "questions#publish"
  patch '/creator/courses/:course_id/questions/:id/add-note', to: "questions#add_note"
  delete '/creator/courses/:course_id/questions/:id/remove-note', to: "questions#remove_note"
  post '/creator/courses/:course_id/questions/:id/resolve-notes', to: "questions#resolve_notes"
  put '/creator/courses/:course_id/questions/:id/hard-update', to: "questions#hard_update"
  delete '/creator/courses/:course_id/questions/:id', to: "questions#destroy"
  post '/courses/:course_id/publish-questions', to: "questions#publish_questions" # Todo: Include /creator namespace
  post '/creator/courses/:course_id/set-source', to: "questions#bulk_set_source"
  post '/creator/courses/:course_id/set-year', to: "questions#bulk_set_year"

  # Todo: Remove this route, questions & explanations should be scoped to courses
  resources :questions do
    get '/explanation', to: "questions#explanation"
  end

  get 'dashboard/carousel'

  get '/user/results', to: "results#recent"
  get 'results/grouped', to: "results#grouped"
  get '/tests/:course_id/submissions', to: "results#test_submissions"
  get '/tests/:course_id/leaderboard', to: "results#leaderboard"
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
  resources :sessions, only: [:update]

  # Flutterwave Gateway
  get '/transactions/initiate', to: "flutterwave_transactions#initiate"
  post '/transactions/verify', to: "flutterwave_transactions#verify"
  post '/transactions/process', to: "flutterwave_transactions#process_transaction"
  # Paystack Gateway
  post '/transactions/paystack/initiate', to: "paystack_transactions#initiate"
  post '/transactions/paystack/verify', to: "paystack_transactions#verify"
  post '/transactions/paystack/process', to: "paystack_transactions#process_transaction"
  # Generic Transaction data
  resources :transactions, only: [:index, :show]

  resources :cards, only: [:index, :destroy]

  resources :guests, only: [:create] do
    post '/invite', to: "guests#invite"
  end

  get '/admin/users', to: "admin#users"
  patch '/admin/suspend-user', to: "admin#suspend_user"
  patch '/admin/delete-user', to: "admin#delete_user"
  get '/admin/courses', to: "admin#courses"
  post '/admin/assign-course', to: "admin#assign_course"
  post '/admin/merge-courses', to: "admin#merge_courses"
  patch '/admin/suspend-course', to: "admin#suspend_course"
  patch '/admin/approve-creator', to: "admin#make_or_approve_creator"
  patch '/admin/reset-creator', to: "admin#reset_creator"
  get '/admin/inspect-transaction', to: "admin#inspect_transaction"
  post '/admin/copy-question', to: "admin#copy_question"
  delete '/admin/delete-result', to: "admin#delete_result"
  patch '/admin/update-result', to: "admin#update_result"
  patch '/admin/update-creator-status', to: "admin#update_creator_status"
  patch '/admin/dummy-course-toggle', to: "admin#dummy_course_toggle"

  post '/automation/assign-course', to: "automation#assign_course"
  post '/automation/create-course', to: "automation#create_course"

  get '/faqs', to: "faqs#index"

  post 'marketing_metrics/source', to: "marketing_metrics#source"
  # Route for root endpoint
  root to: "health_check#index", via: :all

  # Catch all route for non-existent routes (excluding our active storage routes)
  match '*path', to: "application#route_not_found", via: :all, constraints: -> (req) { !req.path.start_with?('/rails/active_storage/') }
end
