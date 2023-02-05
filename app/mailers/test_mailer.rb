class TestMailer < ApplicationMailer
  default from: 'U-Learn Tests <tests@myulearn.com>'

  def expired_test_email
    @email = params[:email]
    @title = params[:title]
    @time_left = params[:time_left]
    mail(to: @email, subject: 'Your U-Learn Test is expired.')
  end

  def close_test_email
    @email = params[:email]
    @title = params[:title]
    mail(to: @email, subject: 'Time to close your U-Learn Test!')
  end

  def test_results_email

  end
end
