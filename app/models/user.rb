class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  has_secure_password
  validates :password, presence: true
  validates :password_confirmation, presence: true

  # Used to serialize the user model on the go without having to render
  def serialized_user
    ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer).as_json
    # ActiveModelSerializers::SerializableResource.new(self, serializer: UserSerializer, root: :profile).as_json
  end

end
