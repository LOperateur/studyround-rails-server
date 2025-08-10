class AddInviteOnlyToTriviaSets < ActiveRecord::Migration[5.2]
  def change
    add_column :trivia_sets, :invite_only, :boolean, default: false
  end
end
