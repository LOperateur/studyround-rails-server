class QuestionAssetSerializer < ActiveModel::Serializer
  attributes :id, :value

  def value
    asset_type = object.asset_type.to_sym

    case asset_type
    when :asset_type_image
      return object.generated_asset_file_url
    when :asset_type_passage
      return object.content
    else
      return nil
    end
  end
end
