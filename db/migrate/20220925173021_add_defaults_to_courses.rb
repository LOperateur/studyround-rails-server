class AddDefaultsToCourses < ActiveRecord::Migration[5.2]
  def change
    change_column_default :courses, :version, from: 1, to: 0
    change_column_default :courses, :sale_status, from: nil, to: 1
    change_column_default :courses, :test, from: nil, to: false
    change_column_default :courses, :private, from: nil, to: false
    change_column_default :courses, :publish_status, from: nil, to: 1
    change_column_default :courses, :course_status, from: nil, to: 1
  end
end
