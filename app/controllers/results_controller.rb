class ResultsController < ApplicationController
  wrap_parameters format: []

  def show
    result = Result.find(params[:id])

    if result.user != current_user
      if result.session_type_test?
        # For tests, raise exception if a user other than the candidate or creator tries to access it
        if result.course.creator != current_user
          raise Errors::ForbiddenError.new(message: "You cannot view this result")
        end
      else
        raise Errors::ForbiddenError.new(message: "You cannot view this result")
      end
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def session_items
    result = Result.find(params[:result_id])
    course = result.course

    if result.user != current_user
      if result.session_type_test?

        # For tests, raise exception if a user other than the candidate or creator tries to access it
        if course.creator != current_user
          raise Errors::ForbiddenError.new(message: "You cannot view this result session")
        end

        # TODO: Pay gated feature
        # If the creator tries to access this while not a pro-user and their access is expired, error out
        # result_expiration = course.test_expiration + ENV['FREE_TEST_SESSION_ACCESS_HOURS'].to_i.hours
        # if !course.creator.pro_account && (result_expiration < Time.now)
        #   raise Errors::ForbiddenError.new(message: "Your access to this result session is expired.")
        # end

      else
        raise Errors::ForbiddenError.new(message: "You cannot view this result session")
      end
    end

    if result.session_type_test?
      # Restrict session item access if reveal answers is false and the course isn't closed yet
      if !course.instructions['reveal_answers'] && !course.course_status_closed?
        raise Errors::ForbiddenError.new(message: "The creator of this course has restricted viewing answers until they close the test. Please check back later.")
      end
    end

    # Doing our own pagination here due to the nature of the query
    total_questions = result.session_items.size
    limit, offset, paginated_metadata = custom_paginate(total_questions, params)

    result_session = result.session_items.to_a.drop(offset).take(limit)
    question_ids = result_session.map { |session_item| session_item["question_id"] }.join(",")

    questions = Question.where("id IN (#{question_ids})")

    # Append the question to the session item using the question_id to match
    # If no matching question is found in the db, skip it
    session_questions = result_session.map.with_index(1) { |session_item, order|
      matching_question = questions.find { |question| question.id == session_item["question_id"] }
      if matching_question
        session_item.merge(matching_question.serialized_question, order: order)
      else
        nil
      end
    }.compact

    render json: { data: session_questions }.merge(paginated_metadata)
  end

  def recent
    results = current_user.results.order(created_at: :desc)
    if params[:course_id].present?
      results = results.where(course_id: params[:course_id])
    end

    paginated_results = paginate(results, params)
    render json: paginated_results, root: :data, meta: paginated_meta(paginated_results)
  end

  def grouped
    latest_distinct_results_query = current_user.results.select('DISTINCT ON (results.course_id) results.id').order('results.course_id, results.created_at desc').to_sql
    count = current_user.results.distinct.count(:course_id) # Unable to do count with "Distinct on" query

    grouped_latest_results = Result.joins(:course).select('results.*, courses.title as title').where("results.id IN (#{latest_distinct_results_query})").order("results.created_at desc")

    paginated_results = paginate(grouped_latest_results, params, count)
    render json: paginated_results, root: :data, meta: paginated_meta(paginated_results), each_serializer: GroupedResultsSerializer, status: :ok
  end

  def test_submissions
    course = Course.find(params[:course_id])
    if !course.test
      raise Errors::ForbiddenError.new(message: "Course must be a Test!")
    end

    if course.creator != current_user
      raise Errors::ForbiddenError.new(message: "You don't have authority to view these test submissions")
    end

    submissions = course.results.order(created_at: :desc)
    paginated_submissions = paginate(submissions)

    render json: paginated_submissions, root: :data, meta: paginated_meta(paginated_submissions), each_serializer: ProfileResultSerializer, status: :ok
  end
end
