class CourseBundlesController < ApplicationController

  skip_before_action :authorize!, only: [:index, :show]

  wrap_parameters format: []

  def index
    course_bundles = paginate(CourseBundle.all.order(created_at: :desc), params)
    render json: course_bundles, root: :data, meta: paginated_meta(course_bundles)
  end

  def show
    course_bundle = CourseBundle.find(params[:id])
    render json: course_bundle, root: :data, serializer: CourseBundleSerializer
  end

  def create
    course_ids = create_course_bundle_params[:courses]&.uniq

    if course_ids.nil? || course_ids.empty?
      raise Errors::ForbiddenError.new(message: "You need to specify at least one course to create a course bundle")
    end

    if course_ids.length > 10
      raise Errors::ForbiddenError.new(message: "You can't create a course bundle with more than 10 courses")
    end

    # Verify that all courses exist, and are available
    if course_ids.any? { |id| !Course.published_active_courses.exists?(id) }
      raise Errors::NotFoundError.new(message: "We cannot find some of the courses you selected")
    end

    course_bundle = CourseBundle.new(create_course_bundle_params.except(:courses))
    course_bundle.creator = current_user

    begin
      CourseBundle.transaction do
        course_bundle.save!
        course_ids.each do |course_id|
          CourseBundlePair.create!(course_bundle: course_bundle, course_id: course_id)
        end
      end
      render json: course_bundle, root: :data, serializer: CourseBundleSerializer, status: :created
    rescue
      raise Errors::NotFoundError.new(message: "Error creating course bundle")
    end
  end

  def update
    course_bundle = CourseBundle.find(params[:id])

    existing_course_ids = course_bundle.courses.pluck(:id).uniq
    new_course_ids = update_course_bundle_params[:courses]&.uniq

    course_ids = (new_course_ids + existing_course_ids).uniq

    if course_ids.length > 10
      raise Errors::ForbiddenError.new(message: "You can't have a course bundle with more than 10 courses")
    end

    # Verify that all courses exist, and are available
    if new_course_ids.any? { |id| !Course.published_active_courses.exists?(id) }
      raise Errors::NotFoundError.new(message: "We cannot find some of the courses you selected")
    end

    course_bundle.update_attributes(update_course_bundle_params.except(:courses))

    begin
      CourseBundle.transaction do
        course_bundle.save!
        (new_course_ids - existing_course_ids).each do |course_id|
            CourseBundlePair.create!(course_bundle: course_bundle, course_id: course_id)
        end
      end
      render json: course_bundle, root: :data, serializer: CourseBundleSerializer, status: :ok
    rescue
      raise Errors::NotFoundError.new(message: "Error creating course bundle")
    end
  end

  def modify
    course_bundle = CourseBundle.find(params[:course_bundle_id])
    course = Course.find(modify_course_bundle_params[:course])

    if course_bundle.courses.include?(course)
      course_bundle_pair = CourseBundlePair.find_by(course_bundle: course_bundle, course: course)
      course_bundle_pair.update!(optional: modify_course_bundle_params[:optional])
    else
      raise Errors::NotFoundError.new(message: "This course is not part of the bundle")
    end

    render json: course_bundle, root: :data, serializer: CourseBundleSerializer
  end

  def destroy
    course_bundle = CourseBundle.find(params[:id])
    course_bundle.destroy!

    render json: { message: "Deleted successfully", data: {} }, status: :ok
  end

  private

  def create_course_bundle_params
    params.permit(:name, :description, :courses => [])
  end

  def update_course_bundle_params
    params.permit(:name, :description, :courses => [])
  end

  def modify_course_bundle_params
    params.permit(:course, :optional)
  end
end
