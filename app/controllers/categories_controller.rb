class CategoriesController < ApplicationController
  skip_before_action :authorize!, only: [:index]
  before_action :check_admin, except: [:index]

  wrap_parameters format: []

  def index
    categories = paginate(Category.all, params)
    render json: categories, root: :data, meta: paginated_meta(categories)
  end

  # All other category routes are admin-only

  def show
    category = Category.find(params[:id])
    render json: category, root: :data, status: :ok
  end

  def create
    category = Category.new(create_update_category_params.except(:parent_category))

    if params.key?(:parent_category)
      parent_category = Category.find_by!(name: params[:parent_category])
      category.parent = parent_category
    end

    category.save!

    render json: category, root: :data, status: :created
  end

  def update
    category = Category.find(params[:id])
    category.assign_attributes(create_update_category_params.except(:parent_category))

    if params.key?(:parent_category)
      parent_category = Category.find_by!(name: params[:parent_category])
      category.parent = parent_category
    end

    category.save!

    render json: category, root: :data, status: :ok
  end

  def destroy
    category = Category.find(params[:id])
    category.destroy!
    render json: { message: "Deleted successfully", data: {} }, status: :ok
  end

  private

  def check_admin
    if current_user.user_type != :admin
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

  def create_update_category_params
    params.permit(:name, :level, :parent_category, :image_url)
  end
end
