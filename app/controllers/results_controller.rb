class ResultsController < ApplicationController
  wrap_parameters format: []

  def recent
    results = paginate(current_user.results.order(created_at: :desc), params)
    render json: results, root: :data, meta: paginated_meta(results)
  end
end
