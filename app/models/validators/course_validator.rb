class CourseValidator < ActiveModel::Validator
  def validate(record)
    if record.sale_status_paid? || record.sale_status_explanations?
      if record.price.nil?
        record.errors.add :price, "must be set for paid courses/tests"
      end

      if record.currency.nil?
        record.errors.add :currency, "should be selected for paid courses/tests"
      end
    end

    if record.test
      if record.instructions.nil?
        record.errors.add :instructions, "must be created for tests"
      end

      if record.test_expiration.nil?
        record.errors.add :test_expiration, "must be set for tests"
      end
    end

    if record.publish_status_published?
      if record.questions.publish_status_published.count < 10
        record.errors.add :course, "having less than 10 published questions cannot be published"
      end
    end
  end
end
