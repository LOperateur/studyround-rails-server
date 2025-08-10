class TestInvitation < ApplicationRecord
  belongs_to :course
  belongs_to :invited_by, class_name: 'User'
  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :course_id }
end

