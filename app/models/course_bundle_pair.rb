class CourseBundlePair < ApplicationRecord
  belongs_to :course_bundle
  belongs_to :course

  validates :course_bundle_id, presence: true
  validates :course_id, presence: true
end
