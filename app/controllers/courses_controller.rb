class CoursesController < ApplicationController
  skip_before_action :authorize!, only: [:index, :show, :categorised, :top_courses, :search]

  wrap_parameters format: []

  def index
    courses = paginate(Course.published_active_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def show
    course = Course.find(params[:id])
    render json: course, root: :data, serializer: FullCourseSerializer
  end

  def categorised
    if current_user.nil?
      # Use left_joins for when you want Categories with 0 courses. Not want we want here, so we use joins
      # Answer gotten from: https://stackoverflow.com/questions/16996618/rails-order-by-results-count-of-has-many-association
      categories = Category.where(level: 1).joins(:courses).group(:id).order('COUNT(courses.id) DESC').take(5)
    else
      categories = current_user.categories.order(affinity: :desc).take(5)
    end

    render json: {
      data: categories.map do |category|
        category.serialized_categorised_course[:category]
      end
    }
  end

  def per_category
    category = Category.find(params[:category_id])
    courses = paginate(category.courses.published_active_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def top_courses
    # Firstly, get non-test, published course results created over the past 120 days
    # Passing in the "results." to avoid unambiguity due to the "joins" statement
    results = Result.created_after(120.days.ago, "results.").published_active_course_results.where.not(mode: :mode_test).limit(200)

    # Group the results by their courses then sort based on the number of results per course
    grouped_courses = results.group(:course).count.sort { |a, b| b.last <=> a.last }.take(10).to_h.keys

    render json: grouped_courses, root: :data
  end

  def recent_courses
    # Get published courses for this user
    results = current_user.results.published_active_course_results.limit(100)

    # Group courses ordering them by date created in descending order
    courses = results.group(:course).count.sort { |a, b| b.first.created_at <=> a.first.created_at }.take(10).to_h.keys

    render json: courses, root: :data
  end

  def search
    search_query = params[:q]
    if search_query.blank?
      found_courses = Course.none
    else
      found_courses = Course.published_active_courses.order(created_at: :desc)
                            .where("lower(title) LIKE ? ", "%#{search_query.downcase}%")
    end

    courses = paginate(found_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses), each_serializer: SearchCourseSerializer
  end
end
