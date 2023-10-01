class User < ApplicationRecord
  include Rails.application.routes.url_helpers

  before_save :downcase_fields
  validates :username, presence: true, uniqueness: true, format: { with: /\A[-a-z0-9_.]+\Z/i }
  validates :email, presence: true, uniqueness: true

  has_secure_password validations: false # To avoid the password validation for social logins
  validates :password, presence: true, length: { minimum: 8 }, confirmation: true, if: :password_required?

  # This is to avoid the password validation for social signups
  attr_accessor :in_oauth_creation_flow
  # This is to mandate password validation for the password reset flow
  attr_accessor :in_reset_password_flow

  has_one :refresh_token, dependent: :destroy
  has_many :courses, dependent: :destroy, class_name: "Course", foreign_key: :creator_id
  has_many :questions, class_name: "Question", foreign_key: :creator_id
  has_many :question_assets, class_name: "QuestionAsset", foreign_key: :creator_id
  has_many :transactions, class_name: "Transaction", foreign_key: :buyer_id
  has_many :interests, dependent: :destroy
  has_many :categories, through: :interests
  has_many :results
  has_many :reviews
  has_many :sessions
  has_many :notifications
  has_many :financial_cards
  has_many :auth_providers
  has_one_attached :profile_image

  scope :active_users, -> { where(user_status: :user_status_active) }
  scope :non_deleted_users, -> { where.not(user_status: :user_status_deleted) }

  enum user_status: {
    user_status_active: 1,
    user_status_suspended: 2,
    user_status_deleted: 3,
  }

  # This is a bare-bones implementation for this
  # We'll revisit the logic for permissions and user types later
  # Todo: Implement better access permission levels
  enum user_type: {
    standard: 1,
    admin: 2,
    content_support: 3,
  }, _prefix: true

  def password_required?
    # Passwords are not required if the user is in the oauth creation flow
    return false if in_oauth_creation_flow

    # Next, passwords are required if the user is in the password reset flow
    return true if in_reset_password_flow

    # return false if auth_providers.where.not(auth_provider: :auth_provider_password).any?

    # Lastly, if the user is being created or the password is being changed, the password is required
    new_record? || password.present?
  end

  def user_type
    if self.email.starts_with?("admin") && self.email.ends_with?("@studyround.com")
      return :admin
    elsif self.email.starts_with?("content") && self.email.ends_with?("@studyround.com")
      return :content_support
    else
      return :standard
    end
  end

  def downcase_fields
    self.username.downcase!
    # self.email.downcase! Not necessary anymore
  end

  # Used to serialize the user model on the go without having to render
  def serialized_user
    ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer).as_json
    # ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer, root: :profile).as_json
  end

  def generated_profile_image_url
    begin
      path = rails_blob_path(self.profile_image, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end

  def has_purchased_item(item)
    # Todo: Should we allow collaborators to access the course or explanations?
    if item.is_a? Course
      item.creator_id == self.id || Transaction.where(buyer_id: self.id, purchase_item_id: item.id).any?
    else
      false
    end
  end
end
