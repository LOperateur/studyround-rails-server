class QuestionAsset < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :course
  has_many :question_asset_references, dependent: :restrict_with_exception # Prevent deletion if referenced by a question
  has_many :questions, through: :question_asset_references
  has_one_attached :file, dependent: :purge_later # Purge the file if the asset is deleted

  # Name can only contain letters, numbers, underscores, and dashes and spaces
  validates :name, format: { with: /\A[a-zA-Z0-9_\- ]+\z/, message: "can only contain letters, numbers, underscores, dashes, and spaces" },
            length: { maximum: 50 }, presence: true

  enum asset_type: {
    asset_type_image: 1,
    asset_type_passage: 2,
  }

  # Used to serialize the question asset model on the go without having to render
  def serialized_question_asset
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionAssetSerializer).as_json[:question_asset]
  end

  def generated_asset_file_url
    begin
      path = rails_blob_path(self.file, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end
end
