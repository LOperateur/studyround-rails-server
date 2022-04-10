class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum course_mode: {
    course_mode_quiz: 1,
    course_mode_practice: 2,
    course_mode_test: 3,
  }
end
