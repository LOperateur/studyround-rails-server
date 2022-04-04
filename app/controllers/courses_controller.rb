class CoursesController < ApplicationController
  skip_before_action :authorize!, only: [:index, :categorised]

  def index
    render json: Course.all, root: :data
  end

  def categorised
  end

  def interest_categorised
  end
end
