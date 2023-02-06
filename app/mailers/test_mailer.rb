class TestMailer < ApplicationMailer
  default from: 'U-Learn Tests <tests@myulearn.com>'

  def expired_test_email
    @email = params[:email]
    @title = params[:title]
    @course_id = params[:course_id]
    @time_left = params[:time_left]
    mail(to: @email, subject: 'Your U-Learn Test is expired.')
  end

  def close_test_email
    @email = params[:email]
    @title = params[:title]
    @course_id = params[:course_id]
    mail(to: @email, subject: 'Time to close your U-Learn Test!')
  end

  def test_results_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @result_id = params[:result_id]
    mail(to: @email, subject: 'Your U-Learn Test Results!')
  end
end
