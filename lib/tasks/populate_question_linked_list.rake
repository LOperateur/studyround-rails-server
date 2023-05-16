namespace :question do
  desc 'Populate next_id and previous_id fields for questions using created_at for sorting'
  task populate_question_linked_list: :environment do
    puts 'Populating linked list fields for questions...'

    Course.non_deleted_courses.each do |course|
      course.questions.non_deleted_questions.order(:created_at).each_cons(2) do |previous_question, next_question|
        previous_question.update(next_id: next_question.id)
        next_question.update(previous_id: previous_question.id)
      end
    end

    puts 'Linked list fields populated successfully.'
  end
end
