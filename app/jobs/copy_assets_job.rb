class CopyAssetsJob < ApplicationJob
  queue_as :default

  def perform(asset_ids, dest_course, src_course)
    # Get all the question assets this question uses and duplicate them in the new course
    src_course.question_assets.where(id: asset_ids.uniq).each do |original_asset|
      # Migrate asset if it doesn't exist in the destination course
      if !dest_course.question_assets.exists?(content_signature: original_asset.content_signature)
        duplicate_asset = original_asset.dup
        duplicate_asset.course = dest_course
        duplicate_asset.creator = dest_course.creator

        begin
          duplicate_asset.save!

          if original_asset.asset_type_image? && original_asset.file.attached?
            duplicate_asset.file.attach(
              io: StringIO.new(original_asset.file.download),
              filename: original_asset.file.filename,
              content_type: original_asset.file.content_type
            )
          end
        rescue => e
          duplicate_asset.destroy
          logger.error("CopyAssetsJob for asset_id #{original_asset.id} with error: #{e}")
        end
      end
    end
  end
end
