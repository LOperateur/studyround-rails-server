module TransactionHelper
  def has_user_purchased_item(user, item)
    if item.is_a? Course
      Transaction.where(buyer_id: user.id, purchase_item_id: item.id).any?
    else
      false
    end
  end
end
