class UserMailer < ApplicationMailer
  default from: 'U-Learn Verification <auth@myulearn.com>'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end

  def demo_result_signup_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @pass_token = params[:pass_token]
    mail(to: @email, from: 'U-Learn Results <auth@myulearn.com>', subject: 'Your U-Learn Results!')
  end
end
