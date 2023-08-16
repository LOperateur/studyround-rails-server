class UserMailer < ApplicationMailer
  default from: 'U-Learn Verification <noreply@myulearn.com>'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end

  def creator_consent_email
    @email = params[:email]
    # Send email to the user and the admin
    recipients = [@email, ENV['ADMIN_CONSENT_EMAIL']]
    mail(to: recipients, from: 'U-Learn Creators <noreply@myulearn.com>', subject: 'Creator Consent')
  end

  def new_creator_email
    @email = params[:email]
    @username = params[:username]
    @password = params[:password]
    mail(to: @email, from: 'U-Learn Creators <noreply@myulearn.com>', subject: 'Creator Credentials')
  end
end
