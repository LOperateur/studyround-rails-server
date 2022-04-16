class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :creator_id, :creator_username, :rating, :image_url, :num_questions, :currency, :price, :sale_status, :messages

  def creator_username
    object.creator.username
  end

  def num_questions
    0
  end

  # Todo: This will only contain the last message
  def messages
    []
  end
end
