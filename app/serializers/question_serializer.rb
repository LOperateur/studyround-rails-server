class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question, :question_image_url, :options,
             :multi_answer, :version, :multiplier, :year, :question_image_asset, :passage_asset

  belongs_to :course, serializer: MiniCourseSerializer

  def question_image_url
    object.generated_question_image_url
  end

  def question_image_asset
    object.question_image_asset
  end

  def passage_asset
    object.passage_asset
  end

  def options
    options_w_assets = object.options
    course = object.course

    options_w_assets&.each do |option|
      # Remove the option_text_raw json content
      option.delete("option_text_raw")

      # Expand the asset id's to dynamically include the option assets
      if option["option_image_asset_id"].present?
        option.merge!({ option_image_asset: course.question_assets.find_by(id: option["option_image_asset_id"])&.serialized_question_asset })
      end
    end

    return options_w_assets
  end
end
