class ResultMailer < ApplicationMailer
  default from: 'StudyRound Results <results@studyround.com>'

  def demo_result_signup_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @pass_token = params[:pass_token]
    mail(to: @email, subject: 'Your StudyRound Results!')
  end

  def test_results_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @course_id = params[:course_id]
    @result_id = params[:result_id]
    mail(to: @email, subject: 'Your StudyRound Test Results!')
  end

  def trivia_results_email
    @email = params[:email]
    @title = params[:title]
    @score = params[:score]
    @trivia_id = params[:trivia_id]
    @result_id = params[:result_id]
    mail(to: @email, subject: 'Your StudyRound Trivia Results!')
  end
end
