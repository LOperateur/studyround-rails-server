class CourseValidator < ActiveModel::Validator
  def validate(record)
    if record.sale_status_paid? || record.sale_status_explanations?
      if record.price.nil?
        record.errors.add :price, "must be set for paid #{course_or_test(record)}s"
      end

      if record.currency.nil?
        record.errors.add :currency, "should be selected for paid #{course_or_test(record)}s"
      end
    end

    if record.test
      if record.instructions.nil?
        record.errors.add :instructions, "must be created for tests"
      end

      if record.test_expiration.nil?
        record.errors.add :test_expiration, "must be set for tests"
      end

      # Min test expiration time is 2 hours from now
      if record.test_expiration < Time.now + 2.hours
        record.errors.add :test_expiration, "should be set at least 2 hours from now"
      end

      # Max test expiration time is 30 days from now
      if record.test_expiration > Time.now + 30.days
        record.errors.add :test_expiration, "date cannot exceed 30 days from now"
      end
    end

    if record.publish_status_published?
      if record.questions.publish_status_published.count < 10
        record.errors.add course_or_test(record).to_sym, "having less than 10 published questions cannot be published"
      end

      if record.instructions.present?
        if record.instructions["max_trials"] > 1 && record.instructions["reveal_answers"] == true
          record.errors.add :instructions, "error - Answers cannot be revealed for tests with multiple attempts"
        end
      end
    end
  end

  private

  def course_or_test(course)
    if course.test
      "test"
    else
      "course"
    end
  end
end
