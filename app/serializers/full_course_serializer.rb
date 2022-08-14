class FullCourseSerializer < DetailedCourseSerializer
  type :course
  attributes :instructions, :private, :publish_status, :course_status, :test_statistics

  def test_statistics
    if object.test

      expiration = object.test_expiration
      results = Result.where(course_id: object.id)
      lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
      closing_time = expiration + (object.instructions['time']).seconds + lag_time
      is_closeable = closing_time < Time.now

      return {
        expiration: expiration,
        users: results.distinct.count(:user_id),
        submissions: results.count,
        closing_time: closing_time,
        closeable: is_closeable,
        result_expiration: if object.creator.pro_account
                             nil
                           else
                             expiration + ENV['FREE_TEST_SESSION_ACCESS_HOURS'].to_i.hours
                           end,
      }
    else
      nil
    end
  end
end
