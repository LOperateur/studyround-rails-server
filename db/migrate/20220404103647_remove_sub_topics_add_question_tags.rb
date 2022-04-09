class RemoveSubTopicsAddQuestionTags < ActiveRecord::Migration[5.2]
  def change
    remove_column :courses, :sub_topics, :string
    add_column :courses, :question_tags, :jsonb
  end
end
