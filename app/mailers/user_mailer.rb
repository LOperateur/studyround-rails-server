class UserMailer < ApplicationMailer
  default from: 'U-Learn Verification <noreply@myulearn.com>'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end

  def creator_consent_email
    @email = params[:email]
    bcc = ["info@myulearn.com"]
    mail(to: @email, bcc: bcc, from: 'U-Learn Creators <noreply@myulearn.com>', subject: 'Creator Consent')
  end
end
