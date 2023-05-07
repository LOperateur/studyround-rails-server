module CurrencyHelper
  def format_with_currency(price, currency)
    delimited_price = ActiveSupport::NumberHelper.number_to_delimited(price)

    case currency
    when 'NGN'
      price = "₦#{delimited_price}"
    when 'USD'
      price = "$#{delimited_price}"
    when 'EUR'
      price = "€#{delimited_price}"
    when 'GBP'
      price = "£#{delimited_price}"
    else
      price = "#{currency} #{delimited_price}"
    end

    return price
  end
end
