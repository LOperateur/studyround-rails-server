class ResultsController < ApplicationController
  wrap_parameters format: []

  def show
    result = Result.find(params[:id])
    if result.user_id != current_user.id
      raise Errors::ForbiddenError.new(message: "You cannot view this result")
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def session_items
    result = Result.find(params[:result_id])
    if result.user_id != current_user.id
      raise Errors::ForbiddenError.new(message: "You cannot view this result session")
    end

    # Doing our own pagination here due to the nature of the query
    total_questions = result.session_items.size
    limit = (params[:page_size].presence || [10, total_questions].min).to_i
    page = (params[:page].presence || 1).to_i
    offset = (page - 1) * limit

    paginated_meta = {
      page: page,
      page_size: limit,
      total: total_questions,
    }

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

    render json: { data: session_questions }.merge(paginated_meta)
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
end
