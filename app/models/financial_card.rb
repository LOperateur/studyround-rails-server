class FinancialCard < ApplicationRecord
  belongs_to :user

  def is_flutterwave_card?
    self.provider == "flutterwave"
  end

  def is_paystack_card?
    self.provider == "paystack"
  end
end
