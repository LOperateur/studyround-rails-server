class CategorisedCourseSerializer < ActiveModel::Serializer
  type :category
  attributes :id, :name

  has_many :courses do
    min = ENV["TOP_COURSE_MIN_RATING_COUNT"].to_i || 1

    if Course.published_active_courses.any?
      average_rating = Course.first.courses_average_rating
      Course.find_by_sql(
        "SELECT courses.*, ((rating * rating_count) + (#{average_rating} * #{min})) / GREATEST(rating_count + #{min}, 1) AS weighted_rating
         FROM courses INNER JOIN categorizations ON courses.id = categorizations.course_id WHERE categorizations.category_id = #{object.id}
         AND publish_status = 2 AND course_status = 1 AND private = false AND rating_count >= #{min}
         ORDER BY weighted_rating DESC NULLS LAST LIMIT 12"
      )
    else
      Course.none
    end

    # Non Sql method. TODO: Figure out if this is more efficient than the sql method above
    # object.courses.published_active_courses.where("rating_count >= ?", min)
    #             .sort_by { |course| course.bayesian_average_rating(average_rating) }.reverse.take(12)
  end
end
