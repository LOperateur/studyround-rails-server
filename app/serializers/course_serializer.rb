class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url, :num_questions, :num_explanations,
             :currency, :price, :sale_status, :version, :test

  belongs_to :creator, serializer: ProfileSerializer

  def image_url
    object.generated_image_url
  end

  def num_questions
    object.questions.published_active_questions.count
  end

  def num_explanations
    object.questions.published_active_questions.where.not(explanation: nil).count
  end
end
