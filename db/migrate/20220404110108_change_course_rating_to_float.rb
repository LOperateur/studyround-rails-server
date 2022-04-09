class ChangeCourseRatingToFloat < ActiveRecord::Migration[5.2]
  def up
    change_column :courses, :rating, :float
  end

  def down
    change_column :courses, :rating, :integer
  end
end
