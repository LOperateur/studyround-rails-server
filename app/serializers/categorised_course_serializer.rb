class CategorisedCourseSerializer < ActiveModel::Serializer
  type :category
  attributes :id, :name

  has_many :courses do
    if Course.any?
      average_rating = Course.first.courses_average_rating
      object.courses.published_active_courses.sort_by { |course| course.bayesian_average_rating(average_rating) }.reverse.take(12)
      # object.courses.published_active_courses.limit(12).order("rating desc nulls last")
    else
      []
    end
  end
end
