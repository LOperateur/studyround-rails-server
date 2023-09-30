# Course serializer showing all details of the course
# specifically reserved for the viewership of the creator/collaborators only.
class CreatorCourseSerializer < UserCourseSerializer
  type :course
  attributes :instructions, :private, :publish_status, :course_status, :num_questions_draft,
             :num_explanations_draft, :last_publish_date, :test_statistics, :sources, :included_question_years_draft

  def num_questions_draft
    object.questions.non_deleted_questions.count
  end

  def num_explanations_draft
    object.questions.non_deleted_questions.where("draft->>'explanation' IS NOT NULL OR explanation IS NOT NULL").count
  end

  def included_question_years_draft
    # Years from the 'year' column
    years = object.questions.non_deleted_questions.where(draft: nil).pluck(:year)

    # Years from the 'draft' JSONB column
    draft_years = object.questions.non_deleted_questions.where.not(draft: nil).pluck("draft->>'year'")

    # Combine and deduplicate
    (years + draft_years).compact.uniq.sort.reject(&:blank?)
  end

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

  def sources
    object.questions.non_deleted_questions.distinct.pluck(:source).compact
  end
end
