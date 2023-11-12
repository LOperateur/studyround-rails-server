class CopyAttachmentJob < ApplicationJob
  queue_as :default

  def perform(is_question, question)
    begin
      if is_question
        from_attachment = question.question_image_draft
        to_attachment = question.question_image
      else
        from_attachment = question.explanation_image_draft
        to_attachment = question.explanation_image
      end

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
