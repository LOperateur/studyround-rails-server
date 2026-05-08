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
    test = result.course # Applies if the result is a test (or course, now deprecated)
    trivia = result.trivia_set # Applies if the result is a trivia

    if result.user != current_user
      if result.session_type_test?

        # For tests, raise exception if a user other than the candidate or creator tries to access it
        if !is_course_creator?(test, current_user)
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
          raise Errors::ForbiddenError.new(message: "You cannot view this result's session")
        end
      else
        raise Errors::ForbiddenError.new(message: "You cannot view this result's session")
      end
    end

    if result.session_type_test?
      # Restrict session item access if reveal answers is false and the course isn't closed yet
      if !test.instructions['reveal_answers'] && !test.course_status_closed?
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
      # Since tests keep refs to session items permanently, this is not an issue for tests
      if result.session_items.blank?
        raise Errors::BaseError.new(message: "This result's session is no longer available", status: 400)
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

  def generate_report
    result = Result.find(params[:result_id])

    if result.user != current_user
      raise Errors::ForbiddenError.new(message: "You cannot generate a report for this result")
    end

    if result.session_type_study?
      raise Errors::BaseError.new(message: "Reports are not available for study sessions", status: 400)
    end

    if result.session_type_test?
      test = result.course
      # Restrict report access if reveal answers is false and the course isn't closed yet
      if !test.instructions['reveal_answers'] && !test.course_status_closed?
        raise Errors::ForbiddenError.new(message: "The creator of this course has restricted viewing reports until they close the test. Please check back later.")
      end
    end

    if result.session_type_trivia?
      trivia = result.trivia_set
      # Restrict report access if reveal answers is false and the Trivia isn't closed yet
      if !trivia.rules['reveal_answers'] && !trivia.trivia_status_closed?
        raise Errors::ForbiddenError.new(message: "The creator of this Trivia has restricted viewing reports until they close the Trivia. Please check back later.")
      end
    end

    # Idempotency: return existing completed report
    existing_report = result.performance_report
    if existing_report&.status_completed?
      render json: existing_report, root: :data, serializer: PerformanceReportSerializer, status: :ok
      return
    end

    if result.session_items.blank?
      raise Errors::BaseError.new(message: "Session data is no longer available for report generation", status: 400)
    end

    service = OpenaiReportService.new(result)
    response = service.generate

    if response[:error]
      report = PerformanceReport.find_or_initialize_by(result: result)
      report.assign_attributes(
        user: current_user,
        status: :failed,
        error_message: response[:error],
      )
      report.save!
      raise Errors::BaseError.new(message: "Failed to generate report: #{response[:error]}", status: 500)
    end

    report = PerformanceReport.find_or_initialize_by(result: result)
    report.assign_attributes(
      user: current_user,
      status: :completed,
      report_content: response[:report],
      prompt_tokens: response[:prompt_tokens],
      completion_tokens: response[:completion_tokens],
      error_message: nil,
    )
    report.save!

    render json: report, root: :data, serializer: PerformanceReportSerializer, status: :ok
  end

  def show_report
    result = Result.find(params[:result_id])

    if result.user != current_user
      raise Errors::ForbiddenError.new(message: "You cannot view this report")
    end

    report = result.performance_report
    if report.nil?
      raise Errors::NotFoundError.new(message: "No report found for this result")
    end

    render json: report, root: :data, serializer: PerformanceReportSerializer, status: :ok
  end

  def grouped
    latest_distinct_results_query = current_user.results.select('DISTINCT ON (results.course_id) results.id').order('results.course_id, results.created_at desc').to_sql
    count = current_user.results.distinct.count(:course_id) # Unable to do count with "Distinct on" query

    grouped_latest_results = Result.joins(:course).select('results.*, courses.title as title').where("results.id IN (#{latest_distinct_results_query})").order("results.created_at desc")

    paginated_results = paginate(grouped_latest_results, params, count)
    render json: paginated_results, root: :data, meta: paginated_meta(paginated_results), each_serializer: GroupedResultsSerializer, status: :ok
  end

end
