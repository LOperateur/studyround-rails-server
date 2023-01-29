class Transaction < ApplicationRecord
  belongs_to :buyer, class_name: 'User'

  validates :transaction_ref, presence: true, uniqueness: true

  scope :course_based_transactions, -> { where(purchase_item_type: [:course, :explanations]) }

  enum transaction_status: {
    transaction_status_pending: 1,
    transaction_status_completed: 2,
    transaction_status_failed: 3,
    transaction_status_cancelled: 4,
  }

  enum purchase_item_type: {
    course: 1,
    explanations: 2,
    # Add more later...
  }, _prefix: true

  enum payment_method: {
    payment_method_card: 1,
    payment_method_others: 2,
  }
end
