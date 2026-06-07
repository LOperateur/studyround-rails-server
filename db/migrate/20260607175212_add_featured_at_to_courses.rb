class AddFeaturedAtToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :featured_at, :datetime
  end
end
