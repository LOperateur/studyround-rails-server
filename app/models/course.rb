class Course < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :creator, class_name: 'User'

  validates :title, presence: true
  validates_with CourseValidator

  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :results
  has_many :questions, dependent: :destroy
  has_many :question_assets, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :sessions
  has_one_attached :image, dependent: :purge_later # Purge the image if the course is deleted

  scope :published_active_courses, -> { where(publish_status: :publish_status_published, course_status: :course_status_active, private: false) }
  scope :visible_courses, -> { where(publish_status: :publish_status_published, course_status: [:course_status_active, :course_status_expired], private: false) }
  scope :non_deleted_courses, -> { where.not(course_status: :course_status_deleted) }

  scope :filtered_by_search, -> (search) { where('title ILIKE ?', "%#{search}%") }

  # This doesn't provide unique results, so we're using the other one. Using distinct also fails on some queries.
  # scope :filtered_by_category, -> (category_ids) { joins(:categorizations).where(categorizations: { category_id: category_ids }) }

  # The inner query fetches all the categorizations for those courses (which could have duplicates)
  # The outer where query just fetches courses that have an ID from that list
  scope :filtered_by_category, -> (category_ids) {
    where(id: joins(:categorizations).where(categorizations: { category_id: category_ids }).select(:id))
  }
  scope :filtered_by_creators, -> (creator_ids) { where(creator_id: creator_ids) }
  scope :filtered_by_test, -> (test) { where(test: test) }

  scope :ordered_by_result_count, -> {
    left_joins(:results).group(:id).order('COUNT(results.id) DESC')
  }
  scope :ordered_by_recent_result_count, -> {
    left_joins(:results).where('results.created_at > ?', 180.days.ago).group(:id).order('COUNT(results.id) DESC')
  }
  # joins is more appropriate here than left_joins because we want to exclude courses with no results
  scope :ordered_by_user_recent_results, -> (user) {
    joins(:results).where(results: { user: user }).group(:id).order('MAX(results.created_at) DESC')
  }

  enum sale_status: {
    sale_status_free: 1,
    sale_status_explanations: 2,
    sale_status_paid: 3,
  }

  enum course_status: {
    course_status_active: 1,
    course_status_suspended: 2,
    course_status_expired: 3, # For tests
    course_status_closed: 4, # For tests
    course_status_deleted: 5,
  }

  # Don't change the order of 1 and 2, referenced in migration
  # 20220418091257_change_course_draft_to_integer.rb
  # 20220418100048_rename_question_course_status.rb
  enum publish_status: {
    publish_status_draft: 1,
    publish_status_published: 2,
  }

  # Used to serialize the course model on the go without having to render
  def serialized_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: CourseSerializer).as_json
  end

  # Used to serialize the course mini-model on the go without having to render
  def serialized_mini_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: MiniCourseSerializer).as_json
  end

  # Used to serialize the user-facing course model on the go without having to render
  def serialized_user_facing_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: UserCourseSerializer).as_json
  end

  # Used to serialize the creator-facing course model on the go without having to render
  def serialized_creators_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: CreatorCourseSerializer).as_json
  end

  def courses_average_rating
    Rails.cache.fetch("courses_average_rating", expires_in: 12.hours) do
      Course.published_active_courses.where.not(rating: [0, nil]).average(:rating) || 0
    end
  end

  def tests_average_rating
    Rails.cache.fetch("tests_average_rating", expires_in: 12.hours) do
      Course.published_active_courses.where(test: true).where.not(rating: [0, nil]).average(:rating) || 0
    end
  end

  def bayesian_average_rating(average = courses_average_rating)
    return 0 if (self.rating_count == 0 || self.rating_count.nil?)

    # We use a formula between ratings and rating count before ordering
    # This will prevent 5-star courses with just 1 review from topping the list
    # https://stackoverflow.com/a/1411268/3993638 and https://en.m.wikipedia.org/wiki/IMDb#Rankings

    # Bayesian average rating formula
    # weighted rating = (R * v + C * m) / (v + m)
    # R = average rating for the course (mean)
    # v = number of ratings for the course
    # m = minimum number of ratings required to be listed in the Top Rated course list
    # C = the mean rating across all courses

    rating = self.rating || 0# R
    rating_count = self.rating_count || 0 # v
    minimum_required_rating_count = ENV["TOP_COURSE_MIN_RATING_COUNT"].to_i || 1 # m
    all_courses_average_rating = average # C

    weighted_rating = ((rating * rating_count) + (all_courses_average_rating * minimum_required_rating_count)) / [(rating_count + minimum_required_rating_count), 1].max

    return weighted_rating
  end

  def generated_image_url
    begin
      path = rails_blob_path(self.image, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end

  def send_test_status_emails
    expiration = self.test_expiration
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (self.instructions['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    if is_closeable
      TestMailer.with(
        email: self.creator.email,
        title: self.title,
        course_id: self.id,
      ).close_test_email.deliver_later
    else
      time_left = closing_time - Time.now

      TestMailer.with(
        email: self.creator.email,
        title: self.title,
        course_id: self.id,
        closing_time: "#{closing_time.to_formatted_s(:long_ordinal)} GMT",
      ).expired_test_email.deliver_later

      TestMailer.with(
        email: self.creator.email,
        title: self.title,
        course_id: self.id,
      ).close_test_email.deliver_later(wait: (time_left).seconds)
    end
  end

end
