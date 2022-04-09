class CategoriesController < ApplicationController
  skip_before_action :authorize!, only: [:index]

  def index
    categories = paginate(Category.all, params)
    render json: categories, root: :data, meta: paginated_meta(categories)
  end
end
