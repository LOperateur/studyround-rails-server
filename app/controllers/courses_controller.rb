class CoursesController < ApplicationController
  require 'action_view'
  require 'action_view/helpers'
  include ActionView::Helpers::DateHelper
  include TestHelper

  skip_before_action :authorize!, only: [:index, :show, :categorised, :top_courses, :search]
  before_action :load_course, only: [:show, :update, :publish, :destroy]

  wrap_parameters format: []

  def index
    courses = paginate(Course.published_active_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def show
    if current_user.nil? || @course.creator != current_user
      render json: @course, root: :data, serializer: DetailedCourseSerializer
    else
      render json: @course, root: :data, serializer: FullCourseSerializer
    end
  end

  def create
    course_params = prepare_received_course_params(create_course_params)
    course = current_user.courses.build(course_params)

    begin
      course.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(course.errors.to_h)
    end
    render json: course, root: :data, serializer: FullCourseSerializer
  end

  def update
    if @course.test
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot update a published Test!")
      end
    end

    # If a course has been published, prevent any changes to price/currency
    # Making it free will be allowed automatically, however, making it paid at a different
    # price from what was originally published will require us to take action first.
    # This will be checked in the validator since going from free->paid will throw an error if price is null.
    if !@course.last_publish_date.nil?
      new_price = update_course_params[:price]
      new_currency = update_course_params[:currency]

      # If changing the price/currency and the price/currency is different from what was there before
      if (!new_price.nil? && @course.price != new_price) || (!new_currency.nil? && @course.currency != new_currency)
        render json: { message: "Please contact us to change the price or currency", data: {} }, status: 200
        return
      end
    end

    course_params = prepare_received_course_params(update_course_params)
    handle_image_update(course_params)
    @course.assign_attributes(course_params.except(:image_url)) # Todo: Remove Image url as a db field

    begin
      @course.save!
      render json: @course, root: :data, serializer: FullCourseSerializer
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(@course.errors.to_h)
    end
  end

  def publish
    if @course.publish_status_published?
      raise Errors::ForbiddenError.new(message: "This #{course_or_test(@course)} is already published!")
    end

    begin
      @course.publish_status = :publish_status_published
      @course.version = @course.version + 1
      @course.last_publish_date = Time.now
      @course.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(@course.errors.to_h)
    end

    render json: @course, root: :data, meta: { message: "Published successfully" },
           serializer: FullCourseSerializer
  end

  def destroy
    if @course.test?
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot delete a published Test!")
      end
    end

    # If a course has never been published, hard delete it as well as all of its questions.
    if @course.last_publish_date.nil?
      @course.destroy!
    else
      begin
        @course.course_status_deleted!
      rescue ActiveRecord::RecordInvalid
        raise Errors::InvalidError.new(@course.errors.to_h)
      end
    end

    render json: { message: "Deleted successfully", data: {} }, status: 200
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
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (course.instructions['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    time_left = distance_of_time_in_words(closing_time, Time.now)
    if !is_closeable
      raise Errors::BaseError.new(message: "Please wait #{time_left} before you can close this test", status: 400)
    end

    # Submit all remaining sessions
    # CourseSessionSubmissionJob.perform_now(course)
    course.sessions.each do |session|
      begin
        get_end_test_result(session.user, session.course)
      rescue Errors::BaseError
        # Ignored
      end
    end

    # Close the test
    course.course_status_closed!

    render json: {}, status: :ok
  end

  def created_courses
    courses = current_user.courses.non_deleted_courses.where(test: false).order(created_at: :desc)
    paginated_courses = paginate(courses, params)
    render json: courses, root: :data, meta: paginated_meta(paginated_courses)
  end

  def created_tests
    tests = current_user.courses.non_deleted_courses.where(test: true).order(created_at: :desc)
    paginated_tests = paginate(tests, params)
    render json: paginated_tests, root: :data, meta: paginated_meta(paginated_tests)
  end

  private

  def load_course
    @course = Course.non_deleted_courses.find(params[:id])
    if @course.creator != current_user
      Errors::ForbiddenError.new(message: "You don't have the authority to change this #{course_or_test(@course)}")
    end
  end

  def course_or_test(course)
    if course.test
      "test"
    else
      "course"
    end
  end

  def prepare_received_course_params(received_params)
    course_params = received_params

    if received_params.key?(:test_expiration)
      test_expiration = DateTime.parse(received_params[:test_expiration])
      course_params[:test_expiration] = test_expiration
    end

    if received_params.key?(:instructions)
      instructions_json = JSON.parse(received_params[:instructions])
      course_params[:instructions] = instructions_json
    end

    if received_params.key?(:category_ids)
      category_json = JSON.parse(received_params[:category_ids])
      course_params[:category_ids] = category_json
    end

    return course_params
  end

  # Image handling in controller during update
  # 1.) image √   image_url √   =>    Changing image
  # 2.) image √   image_url X   =>    New image
  # 3.) image X   image_url √   =>    No changes
  # 4.) image X   image_url X   =>    Deleting image
  def handle_image_update(course_params)
    has_image_to_upload = course_params[:image].present?
    has_image_url_to_retain = course_params[:image_url].present?

    if has_image_to_upload
      # Attach is handled in `assign_attributes` for new or changed image.
      # Deleting any current image first is automatically handled by Active Storage.
    else
      if has_image_url_to_retain
        # No changes, do nothing
      else
        # Delete image
        @course.image.purge_later
      end
    end
  end

  def create_course_params
    params.permit(:creator_id, :title, :sale_status, :price, :currency, :private,
                  :test, :about, :image, :test_expiration, :instructions, :category_ids)
  end

  def update_course_params
    params.permit(:creator_id, :title, :sale_status, :price, :currency, :private,
                  :about, :image, :image_url, :test_expiration, :instructions, :category_ids)
  end

end
