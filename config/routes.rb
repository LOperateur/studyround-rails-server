Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post 'auth/signup'
  post 'auth/login'
  post 'auth/reset'
  post '/otp/generate', to: "auth#generate_otp"
  post '/otp/validate', to: "auth#validate_otp"

end
