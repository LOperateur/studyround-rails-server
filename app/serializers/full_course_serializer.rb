class FullCourseSerializer < DetailedCourseSerializer
  type :course
  attributes :test_expiration, :private, :publish_status,
             :course_status, :test_users, :test_submissions, :test_result_expiration

  def test_users
    if object.test
      Result.where(course_id: object.id).distinct.count(:user_id)
    else
      nil
    end
  end

  def test_submissions
    if object.test
      Result.where(course_id: object.id).count
    else
      nil
    end
  end

  def test_result_expiration
    if object.test
      object.test_expiration + 48.hours
    else
      nil
    end
  end
end
