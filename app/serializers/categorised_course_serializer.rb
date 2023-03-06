class CategorisedCourseSerializer < ActiveModel::Serializer
  type :category
  attributes :id, :name

  has_many :courses do
    min = ENV["TOP_COURSE_MIN_RATING_COUNT"] || 1

    if Course.any?
      average_rating = Course.first.courses_average_rating
      object.courses.published_active_courses.where("rating_count >= ?", min)
            .sort_by { |course| course.bayesian_average_rating(average_rating) }.reverse.take(12)
    else
      []
    end

    # Sql-only method. TODO: Figure out if this is more efficient than the ruby method above
    # Course.find_by_sql(
    #   "SELECT courses.*, ((rating * rating_count) + ((SELECT AVG(rating) FROM courses WHERE publish_status = 2 AND course_status = 1 AND private = false) * #{min})) / (rating_count + #{min}) AS weighted_rating
    #    FROM courses INNER JOIN categorizations ON courses.id = categorizations.course_id WHERE categorizations.category_id = #{object.id}
    #    AND publish_status = 2 AND course_status = 1 AND private = false AND rating_count >= #{min}
    #    ORDER BY weighted_rating DESC NULLS LAST LIMIT 12"
    # )
  end
end
