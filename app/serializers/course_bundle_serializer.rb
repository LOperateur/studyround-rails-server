class CourseBundleSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  # Custom method to serialize courses with the optional value
  attribute :courses

  def courses
    # Manually build the array of courses with their optional values
    # Sort by optional: false first, then true
    object.course_bundle_pairs.sort_by { |pair| pair.optional ? 1 : 0 }.map do |pair|
      {
        id: pair.course.id,
        name: pair.course.title,
        version: pair.course.version,
        optional: pair.optional
      }
    end
  end
end
