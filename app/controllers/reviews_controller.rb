class ReviewsController < ApplicationController
  skip_before_action :authorize!, only: [:index, :show]
  before_action :load_course
  before_action :load_review, only: [:show, :update, :destroy]

  wrap_parameters format: []

  def index
    reviews = paginate(@course.reviews.order(updated_at: :desc), params)
    render json: reviews, root: :data, meta: paginated_meta(reviews)
  end

  def create
    existing_review = @course.reviews.where(user: current_user).take

    if existing_review.nil?
      review = @course.reviews.build(create_update_review_params.merge(user: current_user))
      save_and_calculate review
      render json: review, root: :data, status: :created
    else
      existing_review.assign_attributes(create_update_review_params)
      save_and_calculate existing_review
      render json: existing_review, root: :data, status: :ok
    end
  end

  def show
    render json: @review, root: :data, status: :ok
  end

  def update
    review = @review
    review.assign_attributes(create_update_review_params)

    if review.user.id != current_user.id
      raise Errors::AuthorizationError(message: "You don't have the authority to update this review!")
    end

    save_and_calculate review
    render json: review, root: :data, status: :ok
  end

  def destroy
    if @review.user.id != current_user.id
      raise Errors::AuthorizationError(message: "You don't have the authority to delete this review!")
    end

    @review.destroy
    calculate_average_rating
    render json: {}, status: :ok
  end

  private

  def load_course
    @course = Course.find(params[:course_id])
  end

  def load_review
    begin
      @review = @course.reviews.find(params[:id])
    rescue
      raise Errors::NotFoundError.new(message: "Cannot find review with id #{params[:id]} for course with id #{params[:course_id]}")
    end
  end

  def create_update_review_params
    params.permit(:rating, :review)
  end

  def save_and_calculate(review)
    unless (1..5).include?(review.rating)
      raise Errors::BaseError.new(message: "Invalid rating value")
    end
    review.save!
    calculate_average_rating
  end

  def calculate_average_rating
    review_count = @course.reviews.count.to_f
    rating = review_count == 0 ? 0 : (@course.reviews.sum(:rating) / review_count).round(2)
    @course.rating = rating
    @course.save!
  end
end
