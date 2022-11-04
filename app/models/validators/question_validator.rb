class QuestionValidator < ActiveModel::Validator
  def validate(record)
    # These validations only apply when the question is published
    if record.publish_status_published?
      if record.question.blank?
        record.errors.add :question, "must be set!"
      end

      if record.options.present? && record.options.length == 1
        record.errors.add :options, "must be more than 1"
      end

      if record.answer.blank?
        record.errors.add :answer, "must be set!"
      end

      # Single answer non-german obj questions should only have one answer
      if !record.multi_answer? && record.options.present? && record.answer.present? && record.answer.length > 1
        record.errors.add :answers, "for single answer questions cannot exceed 1"
      end
    end
  end
end