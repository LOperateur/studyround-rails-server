class ResultsController < ApplicationController
  wrap_parameters format: []

  def show
    result = Result.find(params[:id])
    if result.user_id != current_user.id
      raise Errors::AuthorizationError.new(message: "You cannot view this result")
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def recent
    results = paginate(current_user.results.order(created_at: :desc), params)
    render json: results, root: :data, meta: paginated_meta(results)
  end

  def grouped
    latest_distinct_results_query = current_user.results.select('DISTINCT ON (results.course_id) results.id').order('results.course_id, results.created_at desc').to_sql
    count = current_user.results.distinct.count(:course_id) # Unable to do count with "Distinct on" query

    grouped_latest_results = Result.joins(:course).select('results.id, results.created_at, results.total, results.score, results.course_id, courses.title as title').where("results.id IN (#{latest_distinct_results_query})").order("results.created_at desc")

    paginated_result = paginate(grouped_latest_results, params, count)
    render json: paginated_result, root: :data, meta: paginated_meta(paginated_result), each_serializer: GroupedResultsSerializer, status: :ok
  end
end
