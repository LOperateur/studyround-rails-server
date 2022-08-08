class CoursesController < ApplicationController
  require 'action_view'
  require 'action_view/helpers'
  include ActionView::Helpers::DateHelper
  include TestHelper

  skip_before_action :authorize!, only: [:index, :show, :categorised, :top_courses, :search]

  wrap_parameters format: []

  def index
    courses = paginate(Course.published_active_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def show
    course = Course.find(params[:id])
    if current_user.nil? || course.creator != current_user
      render json: course, root: :data, serializer: DetailedCourseSerializer
    else
      render json: course, root: :data, serializer: FullCourseSerializer
    end
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
    results = Result.created_after(120.days.ago, "results.").published_active_course_results.where.not(session_type: :test).limit(200)

    # Group the results by their courses then sort based on the number of results per course
    grouped_courses = results.group(:course).order('count_all desc').count.take(10).to_h.keys
    # grouped_courses = results.group(:course).count.sort { |a, b| b.last <=> a.last }.take(10).to_h.keys

    render json: grouped_courses, root: :data
  end

  def recent_courses
    # Get recently used course results for this user
    results = current_user.results.published_active_course_results.limit(100)

    # Group courses selecting the most recent result for each and sorting them in descending order
    grouped_courses = results.group(:course).order('maximum_created_at desc').maximum(:created_at).take(10).to_h.keys
    # grouped_courses = results.group(:course).maximum(:created_at).sort { |a, b| b.last <=> a.last }.take(10).to_h.keys

    render json: grouped_courses, root: :data
  end

  def search
    search_query = params[:q]
    if search_query.blank?
      found_courses = Course.none
    else
      found_courses = Course.visible_courses.order(created_at: :desc)
                            .where("lower(title) LIKE ? ", "%#{search_query.downcase}%")
    end

    courses = paginate(found_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses), each_serializer: SearchCourseSerializer
  end

  def close_test
    course = Course.find(params[:course_id])
    if course.creator != current_user
      raise Errors::ForbiddenError.new(message: "You don't have the authority to close this test")
    end

    # Confirm that the lag time is exceeded and the test is closeable
    expiration = course.test_expiration
    lag_time = 1.hour
    closing_time = expiration + (course.instructions['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    time_left = distance_of_time_in_words(closing_time, Time.now)
    if !is_closeable
      raise Errors::BaseError.new(message: "Please wait #{time_left} before you can close this test", status: 400)
    end

    # Start a job to submit all remaining sessions
    CourseSessionSubmissionJob.perform_now(course)

    # Close the test
    course.course_status_closed!

    render json: {}, status: :ok
  end
end
