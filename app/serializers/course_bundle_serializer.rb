class CourseBundleSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  # Custom method to serialize courses with the optional value
  attribute :courses

  def courses
    # Manually build the array of courses with their optional values
    object.course_bundle_pairs.map do |pair|
      {
        id: pair.course.id,
        name: pair.course.title,
        description: pair.course.version,
        optional: pair.optional
      }
    end
  end
end
