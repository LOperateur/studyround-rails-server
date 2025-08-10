class TriviaSetSerializer < ActiveModel::Serializer
  attributes :id, :title, :subtitle, :private, :expiration, :trivia_status,
             :invite_only, :course_bundles, :rules

  belongs_to :creator, serializer: MiniProfileSerializer

  def course_bundles
    object.course_bundle_ids.map do |course_bundle_id|
      # Fetch the course bundle
      course_bundle = CourseBundle.find(course_bundle_id)
      {
        id: course_bundle.id,
        name: course_bundle.name,
      }
    end
  end
end
