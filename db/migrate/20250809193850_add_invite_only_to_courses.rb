class AddInviteOnlyToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :invite_only, :boolean, default: false
  end
end
