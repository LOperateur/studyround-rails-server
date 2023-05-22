class AutomationController < ApplicationController
  skip_before_action :authorize!

  def assign_course
    creator_username, reviewer_username = parse_trello_course_desc(assign_course_params[:description].gsub("\n", " "))

    creator = User.find_by(username: creator_username)
    reviewer = User.find_by(username: reviewer_username)

    assignment = assign_course_params[:assign_to]
    course = Course.non_deleted_courses.find_by!(title: assign_course_params[:course])

    if assignment == "creator"
      course.creator = creator
    elsif assignment == "reviewer"
      course.creator = reviewer
    end

    course.save!

    render json: {}, root: :data, status: :ok
  end

  private

  def parse_trello_course_desc(string)
    pattern = /\[(.*?)\]/
    creator, reviewer = string.split("\n").map do |line|
      match = line.match(pattern)
      match[1] if match
    end
    [creator, reviewer]
  end

  def assign_course_params
    params.permit(:course, :description, :assign_to)
  end
end
