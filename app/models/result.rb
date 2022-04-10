class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum mode: {
    mode_quiz: 1,
    mode_practice: 2,
    mode_test: 3,
  }
end
