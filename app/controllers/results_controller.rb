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
end
