class PerformanceReport < ApplicationRecord
  belongs_to :result
  belongs_to :user

  enum status: {
    pending: 1,
    completed: 2,
    failed: 3,
  }, _prefix: true

  validate :result_belongs_to_user

  private

  def result_belongs_to_user
    if result && user && result.user_id != user_id
      errors.add(:user, "must own the result")
    end
  end
end
