class User < ApplicationRecord
  before_save :downcase_fields
  validates :username, presence: true, uniqueness: true, format: { with: /\A[-a-z0-9_.]+\Z/i }
  validates :email, presence: true, uniqueness: true

  has_secure_password
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true, length: { minimum: 8 }

  has_one :refresh_token, dependent: :destroy
  has_many :courses, dependent: :destroy, class_name: "Course", foreign_key: :creator_id
  has_many :transactions, class_name: "Transaction", foreign_key: :buyer_id
  has_many :transactions, class_name: "Transaction", foreign_key: :seller_id
  has_many :interests, dependent: :destroy
  has_many :categories, through: :interests
  has_many :results
  has_many :reviews
  has_many :sessions

  def downcase_fields
    self.username.downcase!
    # self.email.downcase! Not necessary anymore
  end

  # Used to serialize the user model on the go without having to render
  def serialized_user
    ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer).as_json
    # ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer, root: :profile).as_json
  end

end
