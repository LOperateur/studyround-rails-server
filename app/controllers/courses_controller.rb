class CoursesController < ApplicationController
  skip_before_action :authorize!, only: [:index, :categorised]

  def index
    courses = paginate(Course.all, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def categorised
  end

  def interest_categorised
  end
end
