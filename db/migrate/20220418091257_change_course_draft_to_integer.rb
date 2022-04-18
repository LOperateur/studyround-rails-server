class ChangeCourseDraftToInteger < ActiveRecord::Migration[5.2]
  def up
    change_column :courses, :draft, :integer, :using => 'case when draft then 1 else 2 end'
  end

  def down
    change_column :courses, :draft, :boolean, :using => 'case when draft = 1 then TRUE else FALSE end'
  end
end
