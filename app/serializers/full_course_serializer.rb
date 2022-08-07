class FullCourseSerializer < DetailedCourseSerializer
  type :course
  attributes :instructions, :private, :publish_status, :course_status, :test_statistics

  def test_statistics
    if object.test

      expiration = object.test_expiration
      results = Result.where(course_id: object.id)
      lag_time = 1.hour
      closing_time = expiration + (object.instructions['time']).seconds + lag_time
      is_closeable = closing_time < Time.now

      return {
        expiration: expiration,
        users: results.distinct.count(:user_id),
        submissions: results.count,
        result_expiration: if object.creator.pro_account then nil else expiration + 48.hours end,
        closing_time: closing_time,
        closeable: is_closeable,
      }
    else
      nil
    end
  end
end
