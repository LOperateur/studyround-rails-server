class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :creator_id, :creator_username, :rating, :image_url, :num_questions, :currency, :price, :sale_status

  def creator_username
    object.creator.username
  end

  def num_questions
    0
  end
end
