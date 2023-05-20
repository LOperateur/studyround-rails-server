namespace :question do
  desc 'Back fill creator_id for existing questions with the course creator'
  task back_fill_question_creator_id: :environment do
    puts 'Back filling creator_id for questions...'

    Question.where(creator_id: nil).find_each do |question|
      question.update_attribute(:creator_id, question.course.creator_id)
    end

    puts 'Creator_id back filled successfully.'
  end
end
