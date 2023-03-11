module UserInterest
  extend ActiveSupport::Concern

  def register_interest(user, category_ids)
    category_ids.each do |category_id|
      is_previously_interested = false

      # Check if the user is already interested in this category
      user.interests.each do |interest|
        if interest.category_id == category_id
          is_previously_interested = true

          interest.affinity = interest.affinity + 1
          interest.save!
        end
      end

      # If the user has not previously been interested in this category...
      unless is_previously_interested
        interest = user.interests.build(category_id: category_id, affinity: 1)
        if interest
          interest.save!
        end
      end
    end
  end
end