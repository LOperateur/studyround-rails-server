class CopyAttachmentJob < ApplicationJob
  queue_as :default

  def perform(from_attachment, to_attachment)
    begin
      to_attachment.attach(
        io: StringIO.new(from_attachment.download),
        filename: from_attachment.filename,
        content_type: from_attachment.content_type
      )
    rescue
      # Do nothing
    end
  end
end
