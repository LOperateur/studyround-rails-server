class CreatePerformanceReports < ActiveRecord::Migration[5.2]
  def change
    create_table :performance_reports do |t|
      t.references :result, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true, index: true
      t.integer :status, default: 1, null: false
      t.text :report_content
      t.integer :prompt_tokens
      t.integer :completion_tokens
      t.text :error_message

      t.timestamps
    end
  end
end
