module CourseHelper
  extend ActiveSupport::Concern

  def search_and_filter(courses)
    search_query = params[:q] || nil
    category_filters = params[:category] || []
    creator_filters = params[:creator] || []
    test_filter = params[:test] == "true"

    # If strict is set to true, we will only return courses that EXACTLY match the category or creator filters
    strict_match = params[:strict] == "true"

    found_courses = courses

    # Filter by categories, creators, test status and search query if present
    if search_query.present?
      found_courses = found_courses.filtered_by_search(search_query)
    end

    if category_filters.present?
      if strict_match
        category_ids = Category.select(:id).where(name: category_filters)
      else
        # "name ILIKE ? OR name ILIKE ? OR name ILIKE ? ..."
        category_conditions = category_filters.map { "name ILIKE ?" }.join(' OR ')
        category_ids = Category.select(:id).where(category_conditions, *category_filters.map { |filter| "%#{filter}%" }).limit(10)
      end
      found_courses = found_courses.filtered_by_category(category_ids)
    end

    if creator_filters.present?
      if strict_match
        creator_ids = User.select(:id).where(username: creator_filters)
      else
        # "username ILIKE ? OR username ILIKE ? OR username ILIKE ? ..."
        creator_conditions = creator_filters.map { "username ILIKE ?" }.join(' OR ')
        creator_ids = User.select(:id).where(creator_conditions, *creator_filters.map { |filter| "%#{filter}%" }).limit(10)
      end
      found_courses = found_courses.filtered_by_creators(creator_ids)
    end

    if params.key?(:test)
      found_courses = found_courses.filtered_by_test(test_filter)
    end

    return found_courses
  end
end
