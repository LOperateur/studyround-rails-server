class QuestionAssetSerializer < ActiveModel::Serializer
  attributes :id, :value, :asset_type

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

  def asset_type
    asset_type = object.asset_type.to_sym

    case asset_type
    when :asset_type_image
      return "image"
    when :asset_type_passage
      return "passage"
    else
      return nil
    end
  end
end
