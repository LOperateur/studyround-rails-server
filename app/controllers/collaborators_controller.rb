class CollaboratorsController < ApplicationController
  include CourseHelper

  before_action :load_course

  wrap_parameters format: []

  def request_access
    if is_course_owner?(@course, current_user)
      render json: @course, root: :data, status: :ok, meta: { message: "You are already a collaborator on this course" }, serializer: CreatorCourseSerializer
    else
      if @course.course_status_dummy?
        add_to_collaborators(current_user, :editor)
        render json: @course, root: :data, status: :created, meta: { message: "You have been granted access to this course as an Editor" }, serializer: CreatorCourseSerializer
      else
        # Todo: Send an email to the course creator
        render json: { data: {}, message: "Request sent" }, status: :ok
      end
    end
  end

  def grant_access
    if is_course_creator?(@course, current_user) || current_user.user_type == :admin
      # Todo: Implement this
      render json: { data: {}, message: "Still under construction" }, status: :ok
    else
      raise Errors::ForbiddenError.new(message: "You don't have the authority to grant access")
    end
  end

  private

  def add_to_collaborators(user, role)
    CourseCollaborator.create!(course_id: @course.id, user_id: user.id, role: role)
  end

  def load_course
    @course = Course.published_active_or_dummy_courses.find(params[:course_id])
  end
end
