class CourseBundle < ApplicationRecord
  belongs_to :creator, class_name: 'User'

  has_many :course_bundle_pairs, dependent: :destroy
  has_many :courses, through: :course_bundle_pairs
end
