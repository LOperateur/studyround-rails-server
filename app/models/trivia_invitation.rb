class TriviaInvitation < ApplicationRecord
  belongs_to :trivia_set
  belongs_to :invited_by, class_name: 'User'
  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :trivia_set_id }
end
