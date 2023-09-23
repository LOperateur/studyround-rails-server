class UserMailer < ApplicationMailer
  default from: 'StudyRound Verification <noreply@studyround.com>'

  def verify_otp_email
    @email = params[:email]
    @otp = params[:otp]
    mail(to: @email, subject: 'Verify your email')
  end

  def creator_consent_email
    @email = params[:email]
    # Send email to the user and the admin
    recipients = [@email, ENV['ADMIN_CONSENT_EMAIL']]
    mail(to: recipients, from: 'StudyRound Creators <noreply@studyround.com>', subject: 'Creator Consent')
  end

  def new_creator_email
    @email = params[:email]
    @username = params[:username]
    @password = params[:password]
    mail(to: @email, from: 'StudyRound Creators <noreply@studyround.com>', subject: 'Creator Credentials')
  end
end
