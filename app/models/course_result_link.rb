class CourseResultLink < ApplicationRecord
  belongs_to :course
  belongs_to :result
end
