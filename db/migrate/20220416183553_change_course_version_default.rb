class ChangeCourseVersionDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :courses, :version, from: nil, to: 1
  end
end