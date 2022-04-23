class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url, :num_questions, :currency, :price, :sale_status, :creator

  def creator
    creator = object.creator
    {
      id: creator.id,
      username: creator.username
    }
  end

  def num_questions
    object.questions.publish_status_published.count
  end
end
