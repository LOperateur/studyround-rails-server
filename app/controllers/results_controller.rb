class ResultsController < ApplicationController
  include CourseHelper
  include SessionHelper

  wrap_parameters format: []

  def show
    result = Result.find(params[:id])

    if result.user != current_user
      if result.session_type_test?
        # For tests, raise exception if a user other than the candidate or creator tries to access it
        if !is_course_creator?(result.course, current_user)
          raise Errors::ForbiddenError.new(message: "You cannot view this result")
        end
      elsif result.session_type_trivia?
        # For trivia, raise exception if a user other than the candidate or creator tries to access it
        if result.trivia_set.creator != current_user
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
    trivia = result.trivia_set

    if result.user != current_user
      if result.session_type_test?

        # For tests, raise exception if a user other than the candidate or creator tries to access it
        if !is_course_creator?(course, current_user)
          raise Errors::ForbiddenError.new(message: "You cannot view this result session")
        end

        # TODO: Pay gated feature
        # If the creator tries to access this while not a pro-user and their access is expired, error out
        # result_expiration = course.test_expiration + ENV['FREE_TEST_SESSION_ACCESS_HOURS'].to_i.hours
        # if !course.creator.pro_account && (result_expiration < Time.now)
        #   raise Errors::ForbiddenError.new(message: "Your access to this result session is expired.")
        # end

      elsif result.session_type_trivia?
        # For trivia, raise exception if a user other than the candidate or creator tries to access it
        if trivia.creator != current_user
          raise Errors::ForbiddenError.new(message: "You cannot view this result session")
        end
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

    if result.session_type_trivia?
      # Restrict session item access if reveal answers is false and the Trivia isn't closed yet
      if !trivia.rules['reveal_answers'] && !trivia.trivia_status_closed?
        raise Errors::ForbiddenError.new(message: "The creator of this Trivia has restricted viewing answers until they close the Trivia. Please check back later.")
      end
    end

    if !result.session_type_test?
      # For non-test sessions, if session items is empty or nil, then just raise an error
      if result.session_items.blank?
        raise Errors::BaseError.new(message: "This result session is no longer available", status: 400)
      end
    end

    # Doing our own pagination here due to the nature of the query
    total_questions = result.session_items.size
    limit, offset, paginated_metadata = custom_paginate(total_questions, params)

    result_session_items = result.session_items.to_a.drop(offset).take(limit)

    if result.session_type_test?
      session_questions = flesh_out_session_items(result_session_items)
    else
      # Non-test session items should already be fleshed out
      session_questions = result_session_items
    end

    render json: { data: session_questions }.merge(paginated_metadata)
  end

  def recent
    results = current_user.results.order(created_at: :desc)
    if params[:course_id].present?
      # Directly associated results
      direct_results = results.where(course_id: params[:course_id])

      # Indirectly associated results via course_result_links
      multi_course_results = results.joins(:course_result_links).where('course_result_links.course_id = ?', params[:course_id])

      # Combine the two sets
      results = Result.where(id: direct_results).or(Result.where(id: multi_course_results)).order(created_at: :desc)
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

end
