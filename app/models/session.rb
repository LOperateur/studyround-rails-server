class Session < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum session_type: {
    quiz: 1,
    practice: 2,
    study: 3,
    test: 4,
  }, _prefix: true
end
