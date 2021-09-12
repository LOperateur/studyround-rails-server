class UserMailer < ApplicationMailer
  default from: 'U-Learn Verification <auth@operator.com.ng>'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end
end
