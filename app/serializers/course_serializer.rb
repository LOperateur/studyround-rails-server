class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url, :num_questions, :num_explanations,
             :currency, :price, :sale_status, :version, :test

  def num_questions
    object.questions.publish_status_published.count
  end

  def num_explanations
    object.questions.publish_status_published.where.not(explanation: nil).count
  end
end
