class TestMailer < ApplicationMailer
  default from: 'U-Learn Tests <tests@myulearn.com>'

  def expired_test_email
    @email = params[:email]
    @title = params[:title]
    @course_id = params[:course_id]
    @closing_time = params[:closing_time]
    mail(to: @email, subject: 'Your U-Learn Test is expired.')
  end

  def close_test_email
    @email = params[:email]
    @title = params[:title]
    @course_id = params[:course_id]
    mail(to: @email, subject: 'Time to close your U-Learn Test!')
  end
end
