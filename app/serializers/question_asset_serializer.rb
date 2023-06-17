class QuestionAssetSerializer < ActiveModel::Serializer
  attributes :id, :value

  def value
    case object.asset_type
    when :asset_type_image
      return object.generated_asset_file_url
    when :asset_type_passage
      return object.content
    else
      return nil
    end
  end
end
