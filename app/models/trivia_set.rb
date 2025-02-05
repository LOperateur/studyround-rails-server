class TriviaSet < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :sessions, dependent: :nullify

  enum trivia_status: {
    active: 1,
    suspended: 2,
    expired: 3,
    closed: 4,
    deleted: 5,
  }, _prefix: true
end
