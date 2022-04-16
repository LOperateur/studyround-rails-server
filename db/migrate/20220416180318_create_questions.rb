class CreateQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :questions do |t|
      t.references :course, foreign_key: true
      t.integer :question_number
      t.string :question
      t.jsonb :tags
      t.string :question_image_url
      t.jsonb :options
      t.string :answer
      t.string :answer_image_url
      t.boolean :multi_answer
      t.integer :multiplier
      t.string :explanation
      t.string :explanation_image_url
      t.integer :version, default: 1
      t.integer :status

      t.timestamps
    end
  end
end
