class GlobalReviewsController < ApplicationController
  skip_before_action :authorize!

  def index
    # Remove duplicate reviews that may exist due to multi-course sessions
    deduplicated_ids = Review.where.not(review: [nil, '']).select('MAX(id) as id').group(:user_id, :rating, :review)
    reviews = Review.where(id: deduplicated_ids).order(updated_at: :desc)
    reviews = reviews.where(rating: params[:rating]) if params[:rating].present?
    reviews = paginate(reviews, params)
    render json: reviews, root: :data, meta: paginated_meta(reviews)
  end
end
