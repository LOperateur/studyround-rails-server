class AddLastPublishedDateToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :last_publish_date, :datetime
  end
end
