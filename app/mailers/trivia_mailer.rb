class TriviaMailer < ApplicationMailer
  default from: 'StudyRound Trivia <tests@studyround.com>'

  def expired_trivia_email
    @email = params[:email]
    @title = params[:title]
    @trivia_id = params[:trivia_id]
    @closing_time = params[:closing_time]
    mail(to: @email, subject: 'Your StudyRound Trivia is expired.')
  end

  def close_trivia_email
    @email = params[:email]
    @title = params[:title]
    @trivia_id = params[:trivia_id]
    mail(to: @email, subject: 'Time to close your StudyRound Trivia!')
  end
end
