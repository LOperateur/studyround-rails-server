class CourseBundleSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  has_many :courses, through: :course_bundle_pairs, serializer: MiniCourseSerializer
end
