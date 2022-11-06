class AddRatingCountToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :rating_count, :integer
  end
end
