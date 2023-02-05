class TestMailer < ApplicationMailer
  default from: 'U-Learn Tests <tests@myulearn.com>'

  def expired_test_email
    @email = params[:email]
    @time_left = params[:time_left]
    mail(to: @email, subject: 'Your test is expired')
  end

  def close_test_email
    @email = params[:email]
    mail(to: @email, subject: 'Time to close your test!')
  end

  def test_results_email

  end
end
