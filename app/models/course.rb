class Course < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :creator, class_name: 'User'

  validates :title, presence: true
  validates_with CourseValidator

  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :results
  has_many :questions, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :sessions
  has_one_attached :image

  scope :published_active_courses, -> { where(publish_status: :publish_status_published, course_status: :course_status_active, private: false) }
  scope :visible_courses, -> { where(publish_status: :publish_status_published, course_status: [:course_status_active, :course_status_expired], private: false) }
  scope :non_deleted_courses, -> { where.not(course_status: :course_status_deleted) }

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
