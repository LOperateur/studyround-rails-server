class UserMailer < ApplicationMailer
  default from: 'notifications@myulearn.com'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end
end
