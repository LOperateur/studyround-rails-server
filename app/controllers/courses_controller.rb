class CoursesController < ApplicationController
  require 'action_view'
  require 'action_view/helpers'
  include ActionView::Helpers::DateHelper
  include CourseHelper
  include TestHelper

  before_action :default_12_page_size, only: [:index, :per_category, :enrolled_courses, :search, :my_courses, :tests, :purchased_courses, :purchased_tests, :created_courses]
  skip_before_action :authorize!, only: [:index, :show, :categorised, :similar_courses, :top_courses, :trending_courses, :search]
  before_action :check_creators_consent, only: [:create]
  before_action :load_creators_course, only: [:update, :publish, :destroy, :halt_attempts, :close_test]

  wrap_parameters format: []

  def index
    found_courses = search_and_filter(Course.published_active_courses.ordered_by_result_count)

    # Specifying entry count here due to the result group count query which returns a hash of { grouped courses -> result count }
    # https://api.rubyonrails.org/v7.0.6/classes/ActiveRecord/Calculations.html#method-i-count
    courses = paginate(found_courses, params, entries = found_courses.count.size)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def show
    @course = Course.non_deleted_courses.find(params[:id])

    # Track the purchase of items available for sale in this course
    purchase_status = {}

    if @course.sale_status_paid?
      purchase_status[:sale_status_paid] = current_user.present? && current_user.has_purchased_item(@course)
    end

    if @course.sale_status_explanations?
      purchase_status[:sale_status_explanations] = current_user.present? && current_user.has_purchased_item(@course)
    end

    review = @course.reviews.where(user: current_user).take

    # If current user is not a creator/collaborator on the course, return the user facing course
    if !is_course_owner?(@course, current_user)
      if @course.publish_status_draft? || @course.course_status_suspended?
        raise Errors::ForbiddenError.new(message: "This #{course_or_test(@course)} is currently unavailable. It may have been unpublished or suspended.")
      end
      render json: { data: @course.serialized_user_facing_course[:course].merge(purchase_status: purchase_status, user_review: review) }
    else
      render json: { data: @course.serialized_creators_course[:course].merge(purchase_status: purchase_status, user_review: review) }
    end
  end

  def create
    case current_user.creator_status.to_sym
    when :creator_status_limited
      if current_user.courses.non_deleted_courses.count >= 10
        raise Errors::ForbiddenError.new(message: "You have a limited creator status. You can only create 10 courses")
      end
    when :creator_status_full
      if current_user.courses.non_deleted_courses.count >= 200
        raise Errors::ForbiddenError.new(message: "You have reached the maximum number of courses you can create")
      end
    else
      # Do nothing
    end

    course_params = prepare_received_course_params(create_course_params)
    course = current_user.courses.build(course_params)
    course.private = true if current_user.user_type != :admin # Temp solution

    course.save!
    render json: course, root: :data, serializer: CreatorCourseSerializer
  end

  def update
    if @course.test
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot update a published Test!")
      end
    end

    course_params = prepare_received_course_params(update_course_params)

    if current_user.user_type != :admin
      # If a course has been published, prevent any changes to price/currency
      # Making it free will be allowed automatically, however, making it paid at a different
      # price from what was originally published will require us to take action first.
      # This will be checked in the validator since going from free->paid will throw an error if price is null.
      if @course.last_publish_date.present?
        new_price = course_params[:price]
        new_currency = course_params[:currency]

        # If changing the price/currency and the price/currency is different from what was there before
        if !new_price.nil? && @course.price != new_price.to_d
          raise Errors::BaseError.new(message: "Please contact us to change the price", status: 400)
        end

        if !new_currency.nil? && @course.currency != new_currency
          raise Errors::BaseError.new(message: "Please contact us to change the currency", status: 400)
        end
      end
    end

    handle_image_update(course_params)
    @course.assign_attributes(course_params.except(:image_url))
    @course.private = true if current_user.user_type != :admin # Temp solution

    @course.save!
    render json: @course, root: :data, serializer: CreatorCourseSerializer
  end

  def publish
    if @course.publish_status_published?
      raise Errors::ForbiddenError.new(message: "This #{course_or_test(@course)} is already published!")
    end

    @course.publish_status = :publish_status_published
    @course.version = @course.version + 1
    @course.last_publish_date = Time.now
    @course.save!

    render json: @course, root: :data, meta: { message: "Published successfully" }, serializer: CreatorCourseSerializer
  end

  def destroy
    if @course.test?
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot delete a published Test!")
      end
    end

    # If a course has never been published, hard delete it as well as all of its questions.
    if @course.last_publish_date.nil?
      # If the course is getting destroyed, ensure that all questions are also destroyed atomically
      Course.transaction do
        # Reset all question references to nil
        @course.questions.update_all(previous_id: nil, next_id: nil)
        @course.destroy!
      end
    else
      @course.course_status_deleted!
    end

    render json: { message: "Deleted successfully", data: {} }, status: 200
  end

  def categorised
    if current_user.nil? || current_user.categories.empty?
      # Use left_joins for when you want Categories with 0 courses. Not want we want here, so we use joins
      # Answer gotten from: https://stackoverflow.com/questions/16996618/rails-order-by-results-count-of-has-many-association
      ordered_categories = Category.published_active_course_categories.group(:id).order('COUNT(courses.id) DESC').take(5)
    else
      categories = current_user.categories.order(affinity: :desc).take(5)
      ordered_categories = []

      # If the user's category has less than 3 courses, don't include the category in the list
      categories.each do |category|
        if category.courses.published_active_courses.count >= 3
          ordered_categories.push(category)
        end
      end

      # Then add more categories to make up the 5 and ensure that no category is repeated
      if ordered_categories.size < 5
        ordered_categories += Category.published_active_course_categories.where.not(id: categories.map(&:id))
                              .group(:id).order('COUNT(courses.id) DESC').take(5 - ordered_categories.size)
      end
    end

    render json: {
      data: ordered_categories.map do |category|
        category.serialized_categorised_course[:category]
      end
    }
  end

  def per_category
    category = Category.find(params[:category_id])
    courses = paginate(category.courses.published_active_courses, params)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def similar_courses
    @course = Course.published_active_courses.find(params[:course_id])

    # Get the course's categories
    course_categories = @course.categories.select(:id)

    # Get all courses that have at least one category in common with the course
    # Then group them by the number of categories they have in common with the course
    # Then sort them in descending order by the number of categories they have in common with the course.
    similar_courses = Course.published_active_courses.joins(:categories).where.not(id: @course.id)
                            .where(categories: { id: course_categories })
                            .group(:id).order('COUNT(courses.id) DESC')

    # Specifying entry count here due to the Category group count query which returns a hash of { grouped courses -> category count }
    courses = paginate(similar_courses, params, entries = similar_courses.count.size)
    render json: courses, root: :data, meta: paginated_meta(courses)
  end

  def top_courses
    # Calculate Bayesian average rating for each course
    min = ENV["TOP_COURSE_MIN_RATING_COUNT"].to_i || 1

    if Course.published_active_courses.any?
      average_rating = Course.take.courses_average_rating
      top_courses = Course.find_by_sql(
        "SELECT *, ((rating * rating_count) + (#{average_rating} * #{min})) / GREATEST(rating_count + #{min}, 1) AS weighted_rating
         FROM courses WHERE publish_status = 2 AND course_status = 1 AND private = false AND rating_count >= #{min}
         ORDER BY weighted_rating DESC NULLS LAST LIMIT 10"
      )
    else
      top_courses = Course.none
    end

    # Non sql method. TODO: Figure out if this is more efficient than the sql method above
    # top_courses = Course.published_active_courses.where("rating_count >= ?", min)
    #                     .sort_by { |course| course.bayesian_average_rating(average_rating) }.reverse.take(10)

    render json: top_courses, root: :data
  end

  def trending_courses
    # Get published courses having results created over the past 180 days
    # Then sort those courses by the result count
    courses = Course.published_active_courses.ordered_by_recent_result_count.limit(10)

    render json: courses, root: :data
  end

  def recent_courses
    # Fetch the test for any ongoing test sessions for this user
    ongoing_tests = Session.where(session_type: :test).limit(10).map { |session| session.course }

    # Get recently used course results
    results = current_user.results.published_active_course_results.limit(500)

    # Group courses selecting the most recent result for each and sorting them in descending order
    grouped_courses = results.group(:course).order('maximum_created_at desc').maximum(:created_at).take(10).to_h.keys
    # grouped_courses = results.group(:course).maximum(:created_at).sort { |a, b| b.last <=> a.last }.take(10).to_h.keys

    # Render both lists
    combined = (ongoing_tests + grouped_courses).uniq
    render json: combined, root: :data
  end

  def enrolled_courses
    enrolled_courses = search_and_filter(Course.published_active_courses.ordered_by_user_recent_results(current_user))

    # Specifying entry count here due to the result group count query which returns a hash of { grouped courses -> result count }
    # https://api.rubyonrails.org/v7.0.6/classes/ActiveRecord/Calculations.html#method-i-count
    paginated_enrolled_courses = paginate(enrolled_courses, params, entries = enrolled_courses.count.size)
    render json: paginated_enrolled_courses, root: :data, meta: paginated_meta(paginated_enrolled_courses)
  end

  def search
    found_courses = search_and_filter(Course.published_active_courses.ordered_by_result_count)

    # Specifying entry count here due to the result group count query which returns a hash of { grouped courses -> result count }
    # https://api.rubyonrails.org/v7.0.6/classes/ActiveRecord/Calculations.html#method-i-count
    courses = paginate(found_courses, params, entries = found_courses.count.size)
    render json: courses, root: :data, meta: paginated_meta(courses), each_serializer: SearchCourseSerializer
  end

  def halt_attempts
    message = halt_new_attempts(@course)

    render json: @course, meta: { message: message }, root: :data, serializer: CreatorCourseSerializer
  end

  def close_test
    # Todo: Review this in pt. 2 of the collaborator change
    # Admins have superuser privileges but can't close tests that aren't theirs.
    if !is_course_creator?(@course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have the authority to close this test")
    end

    # Confirm that the lag time is exceeded and the test is closeable
    expiration = @course.test_expiration
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (@course.instructions['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    time_left = distance_of_time_in_words(closing_time, Time.now)
    if !is_closeable
      raise Errors::BaseError.new(message: "Please wait #{time_left} before you can close this test", status: 400)
    end

    # Submit all remaining sessions
    # Alternative?: CourseSessionSubmissionJob.perform_later(course)
    @course.sessions.each do |session|
      begin
        get_end_test_result(session.user, session.course)
      rescue Errors::BaseError
        # Ignored
      end
    end

    # Close the test
    @course.course_status_closed!

    # Send an email to all test-takers
    TestResultsEmailSendJob.perform_later(@course)

    render json: @course, meta: { message: "Test is now Closed!" }, root: :data, serializer: CreatorCourseSerializer
  end

  def my_courses
    # TODO: Also include interests in this query
    # Raw SQL query for fetching courses prioritized by user results
    # -- This SQL query fetches all courses with two additional columns: sort_order and total_results.
    # -- sort_order prioritizes courses with the user's results, and total_results counts all results per course.
    # -- A subquery gets the most recent result for each course for the current user.
    # -- The query sorts courses based on the user's results, most recent user result, and total course results.
    sql = <<-SQL
      WITH user_results AS (
        SELECT DISTINCT ON (course_id) results.*
        FROM results
        WHERE user_id = ?
        ORDER BY course_id, created_at DESC
      )
      SELECT courses.*, 
        CASE WHEN user_results.user_id = ? THEN 0 ELSE 1 END AS sort_order,
        COUNT(all_results.id) AS total_results
      FROM courses
      LEFT OUTER JOIN user_results ON user_results.course_id = courses.id
      LEFT OUTER JOIN results AS all_results ON all_results.course_id = courses.id
      WHERE courses.publish_status = 2
      AND courses.course_status = 1
      AND courses.test = false
      GROUP BY courses.id, user_results.user_id, user_results.created_at
      ORDER BY sort_order, user_results.created_at DESC, total_results DESC, courses.id
      LIMIT ? OFFSET ?
    SQL

    total_published_active_courses = Course.published_active_courses.where(test: false).count
    limit, offset, paginated_metadata = custom_paginate(total_published_active_courses, params)

    # Fetch courses using find_by_sql
    my_courses = Course.find_by_sql([sql, current_user.id, current_user.id, limit, offset])

    render json: { data: my_courses.map do |course|
      course.serialized_course[:course]
    end
    }.merge(paginated_metadata)
  end

  def tests
    # Calculate Bayesian average rating for each test
    min = ENV["TOP_TEST_MIN_RATING_COUNT"].to_i || 1

    # Doing our own pagination here due to the nature of the query (find_by_sql returns an array not an ActiveRecord::Relation)
    total_rated_tests = Course.published_active_courses.where(test: true).where("rating_count >= ?", min).count
    limit, offset, paginated_metadata = custom_paginate(total_rated_tests, params)

    if Course.published_active_courses.where(test: true).any?
      average_rating = Course.take.tests_average_rating
      top_tests = Course.find_by_sql(
        "SELECT *, ((rating * rating_count) + (#{average_rating} * #{min})) / GREATEST(rating_count + #{min}, 1) AS weighted_rating
         FROM courses WHERE publish_status = 2 AND course_status = 1 AND private = false AND test = true AND rating_count >= #{min}
         ORDER BY weighted_rating DESC NULLS LAST LIMIT #{limit} OFFSET #{offset}"
      )
    else
      top_tests = Course.none
    end

    render json: { data: top_tests.map do |test|
      test.serialized_course[:course]
    end
    }.merge(paginated_metadata)
  end

  def purchase
    @course = Course.published_active_courses.find(params[:id])

    if current_user.has_purchased_item(@course)
      raise Errors::BaseError.new(message: "You have already purchased this item", status: 400)
    end

    transactions_controller = TransactionsController.new
    transactions_controller.request = request
    transactions_controller.response = response

    purchase_params = { item_id: params[:id], card_id: purchase_course_params[:card_id] }

    if @course.sale_status_paid?
      purchase_params[:item_type] = :course
    elsif @course.sale_status_explanations?
      purchase_params[:item_type] = :explanations
    else
      raise Errors::BaseError.new(message: "There's nothing to purchase here", status: 400)
    end

    transactions_controller.params = purchase_params

    render json: transactions_controller.process_transaction
  end

  def purchased_courses
    course_transaction_ids = Transaction.select(:purchase_item_id)
                                        .where("buyer_id = ?", current_user.id)
                                        .order(completed_at: :desc)
                                        .course_based_transactions.transaction_status_completed
                                        .map { |transaction| transaction["purchase_item_id"] }
                                        .uniq
    purchased_courses = Course.where(id: course_transaction_ids).where(test: false).sort_by { |i| course_transaction_ids.index(i.id) }

    paginated_purchased_courses = paginate(purchased_courses, params)
    render json: paginated_purchased_courses, root: :data, meta: paginated_meta(paginated_purchased_courses)
  end

  def purchased_tests
    course_transaction_ids = Transaction.select(:purchase_item_id)
                                        .where("buyer_id = ?", current_user.id)
                                        .order(completed_at: :desc)
                                        .course_based_transactions.transaction_status_completed
                                        .map { |transaction| transaction["purchase_item_id"] }
                                        .uniq
    purchased_tests = Course.where(id: course_transaction_ids).where(test: true).sort_by { |i| course_transaction_ids.index(i.id) }

    paginated_purchased_tests = paginate(purchased_tests, params)
    render json: paginated_purchased_tests, root: :data, meta: paginated_meta(paginated_purchased_tests)
  end

  def created_courses
    courses = search_and_filter(current_user.courses.non_deleted_courses.order(created_at: :desc))

    if params.key?(:test)
      if params[:test] == "true"
        courses = courses.where(test: true)
      else
        courses = courses.where(test: false)
      end
    end

    paginated_courses = paginate(courses, params)
    render json: paginated_courses, root: :data, meta: paginated_meta(paginated_courses)
  end

  private

  def load_creators_course
    @course = Course.non_deleted_courses.find(params[:id])
    # Todo: Add more fine-grained permissions in the Collaborator part 2
    if !is_course_owner?(@course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have the authority to change this #{course_or_test(@course)}")
    end
  end

  def check_creators_consent
    if current_user.creator_status_none?
      raise Errors::ForbiddenError.new(message: "You must agree to the creator terms before you can create a course")
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

    # Prevent non-admin users to send in a price or sale_status
    # TODO: For now, only admins can set these values
    if current_user.user_type != :admin
      course_params.delete(:price)
      course_params.delete(:currency)
      course_params.delete(:sale_status)
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
        @course.image.purge
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

  def purchase_course_params
    params.permit(:card_id)
  end

end
