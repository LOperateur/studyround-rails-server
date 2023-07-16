class CreatorQuestionSerializer < QuestionAnswerSerializer
  type :question
  attributes :previous_question_id, :next_question_id, :question_raw, :explanation,
             :explanation_image_url, :explanation_image_asset, :explanation_raw,
             :remaining_edits, :notes, :draft

  belongs_to :creator, serializer: MiniProfileSerializer

  def previous_question_id
    object.previous_id
  end

  def next_question_id
    object.next_id
  end

  def explanation_image_url
    object.generated_explanation_image_url
  end

  def explanation_image_asset
    object.explanation_image_asset
  end

  def remaining_edits
    [6 - object.version, 5].min
  end

  def draft
    # Expand the asset id's to dynamically include the draft assets
    draft_w_assets = object.draft
    course = object.course

    if object.draft&.dig("question_image_asset_id").present?
      draft_w_assets.merge!({ question_image_asset: course.question_assets.find_by(id: object.draft["question_image_asset_id"])&.serialized_question_asset })
    end

    if object.draft&.dig("explanation_image_asset_id").present?
      draft_w_assets.merge!({ explanation_image_asset: course.question_assets.find_by(id: object.draft["explanation_image_asset_id"])&.serialized_question_asset })
    end

    if object.draft&.dig("passage_asset_id").present?
      draft_w_assets.merge!({ passage_asset: course.question_assets.find_by(id: object.draft["passage_asset_id"])&.serialized_question_asset })
    end

    draft_w_assets&.dig("options")&.each do |option|
      if option["option_image_asset_id"].present?
        option.merge!({ option_image_asset: course.question_assets.find_by(id: option["option_image_asset_id"])&.serialized_question_asset })
      end
    end

    return draft_w_assets
  end

end
