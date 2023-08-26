class CategoriesController < ApplicationController
  skip_before_action :authorize!, only: [:index]
  before_action :check_admin, except: [:index]

  wrap_parameters format: []

  def index
    # If the user is not logged in or has no occupation, get the category order tailored for default users
    # Information about the category orders can be found in the Category model
    category_order = [1, 4, 5, 2, 3]

    # If logged in and the user has an occupation
    if current_user&.occupation != nil
      # Get the user's occupation
      occupation = current_user.occupation

      # If the occupation starts with "Student", get the category order tailored for students
      if occupation.start_with?("Student")
        category_order = [5, 3, 2, 1, 4]
      # If the occupation starts with "Professional", get the category order tailored for professionals
      elsif occupation.start_with?("Professional")
        category_order = [4, 1, 5, 3, 2]
      # If the occupation starts with anything else, get the category order tailored for default users
      end
    end

    # Fetch all categories ordered by their level as specified in the category order then by their name
    category_order_sql = category_order.map.with_index { |level, index| "WHEN #{level} THEN #{index}" }.join(' ')
    categories = Category.order(Arel.sql("CASE level #{category_order_sql} END, name"))

    paginated_categories = paginate(categories, params)
    render json: paginated_categories, root: :data, meta: paginated_meta(paginated_categories)
  end

  # All other category routes are admin-only

  def show
    category = Category.find(params[:id])
    render json: category, root: :data, status: :ok
  end

  def create
    category = Category.update!(create_update_category_params)
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

  def generate_default_categories
    category_definitions = {
        "1-faculty" => ["General Knowledge", "Engineering", "Medical Sciences", "Agriculture", "Sciences", "Legal", "Arts & Humanities", "Business", "Social Sciences", "Education", "Environmental Sciences"],
        "2-examinations" => ["JAMB", "Post UTME", "WAEC"],
        "3-institutions" => ["UNIBEN", "DELSU"],
        "4-sectors" => ["Finance", "Technology", "Fashion", "Health & Wellness", "International", "Government", "History", "Entertainment", "Sports", "Religious", "IQ"],
        "5-institution-type" => ["University", "College", "Polytechnic", "Secondary", "Primary", "Adult School"]
    }

    # Loop through each category definition
    category_definitions.each do |level_name, categories|
      # Get the level
      level = level_name.split("-")[0].to_i

      # Loop through each category in the level
      categories.each do |category|
        # If the category already exists, just update it
        if Category.exists?(name: category)
          Category.find_by(name: category).update!(level: level)
        else
          Category.create!(name: category, level: level)
        end
      end
    end

    render json: { message: "Generated successfully", data: {} }, status: :ok
  end

  private

  def check_admin
    if current_user.user_type != :admin
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

  def create_update_category_params
    params.permit(:name, :level, :image_url)
  end
end
