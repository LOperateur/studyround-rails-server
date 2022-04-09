class CoursesController < ApplicationController
  skip_before_action :authorize!, only: [:index, :categorised]

  def index
    courses = paginate(Course.all, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def categorised
    categories = Category.all.take(5)
    render json: {
      data: categories.map do |category|
        category.serialized_categorised_course[:category]
      end
    }
  end

  def interest_categorised
    categories = current_user.categories.order(affinity: :desc).take(5)
    render json: {
      data: categories.map do |category|
        category.serialized_categorised_course[:category]
      end
    }
  end
end
