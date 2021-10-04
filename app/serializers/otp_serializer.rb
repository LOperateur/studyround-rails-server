class OtpSerializer < ActiveModel::Serializer
  attributes :otp_id
  def otp_id
    object.id
  end
end
