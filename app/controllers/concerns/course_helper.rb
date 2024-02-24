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

  # Check if the supplied user is among the owners of the course.
  # Owners can include the original creator, collaborators and the site admins.
  # Todo: In pt 2 of collaborators, limit the collaborator permission by role
  def is_course_owner?(course, user)
    return false if user.nil?
    return course.creator == user ||
      user.user_type == :admin ||
      CourseCollaborator.where(user: user, course: course).exists?
  end

  # Check if the supplied user is strictly the creator of the course.
  # No one, not even admins are the creators, except the actually creator
  def is_course_creator?(course, user)
    return false if user.nil?
    return course.creator == user
  end
end
