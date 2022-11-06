class Transaction < ApplicationRecord
  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User', optional: true

  scope :course_based_transactions, -> { where(purchase_item_type: [:purchase_item_type_course, :purchase_item_type_explanations]) }

  enum transaction_status: {
    transaction_status_created: 1,
    transaction_status_completed: 2,
    transaction_status_pending: 3,
    transaction_status_failed: 4,
    transaction_status_cancelled: 5,
  }

  enum purchase_item_type: {
    purchase_item_type_course: 1,
    purchase_item_type_explanations: 2,
    # Add more later...
  }

  enum payment_method: {
    payment_method_card: 1,
    payment_method_bank: 2,
  }
end
