class ResultMailer < ApplicationMailer
  default from: 'U-Learn Results <results@myulearn.com>'

  def demo_result_signup_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @pass_token = params[:pass_token]
    mail(to: @email, subject: 'Your U-Learn Results!')
  end

  def test_results_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @result_id = params[:result_id]
    mail(to: @email, subject: 'Your U-Learn Test Results!')
  end
end
