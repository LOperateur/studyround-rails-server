class TriviaSessionsController < ApplicationController
  include SessionHelper
  include TriviaHelper

  before_action :load_trivia_courses, only: [:trivia_instructions]

  wrap_parameters format: []

  def trivia_instructions
    trivia = TriviaSet.non_deleted_trivia.find(instruction_params[:trivia_id])
    instructions_response = init_trivia_session_instructions(current_user, trivia, @courses)

    render json: {
      data: instructions_response
    }
  end

  def update_trivia_session
    session = Session.find(params[:id])

    if session.nil?
      # Check for the result if there's no session
      result = current_user.results.find_by(
        session_key: idempotent_session_key(current_user.id, session_id)
      )

      # Ideally, the result should not be nil if this endpoint is called when resuming a trivia session
      if result.nil?
        # Both Session and Result are non-existent, throw an error
        raise Errors::NotFoundError.new(message: "Cannot find session or result. Please refresh this page")
      else
        # Result available, render that for the user to see as an error
        raise Errors::ForbiddenError.new(
              message: "This session is already over",
              action: :submit,
              data: result
            )
      end
    end

    if check_session_for_valid_update(session)
      # Update session
      session.update_attributes!(update_test_session_params)
    else
      raise_ended_trivia_session_error(current_user, session.trivia_set)
    end

    render json: {}, status: :ok
  end

  # Returns nil if the session is active indicating it can be resumed
  # Or creates/returns a result if the session is over.
  def verify_active_trivia_session
    session_id = params[:id]

    if session_id.nil?
      raise Errors::BaseError.new(message: "No session ID provided", status: 400)
    end

    # Confirm the presence of the session
    # Using find_by to prevent throwing an error
    session = Session.find_by(id: session_id)

    if session.nil?
      # Check for the result if there's no session
      result = current_user.results.find_by(
        session_key: idempotent_session_key(current_user.id, session_id)
      )

      # Ideally, the result should not be nil if this endpoint is called when resuming a test
      if result.nil?
        # Both Session and Result are non-existent, throw an error
        raise Errors::NotFoundError.new(message: "Cannot find session or result. Please refresh this page")
      else
        # Result available, render that for the user to see
        render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
      end

      return
    end

    if session.user != current_user
      raise Errors::ForbiddenError.new(message: "This is not your session to resume!")
    end

    if check_session_for_valid_update(session)
      # Session still valid, `/start` will be called to resume it
      render json: { data: nil }, status: :ok
    else
      # Session is stale, convert it to a result
      result = get_end_trivia_result(current_user, session.trivia_set)
      render json: result, root: :data, serializer: SessionResultSerializer, status: :created
    end
  end

  private

  def load_trivia_courses
    begin
      @courses = []
      course_ids = instruction_params[:courses]

      course_ids.each do |course_id|
        @courses << Course.session_accessible_courses.find(course_id)
      end

    rescue ActiveRecord::RecordNotFound
      error_message = "Some course data was not found - it may have been removed"
      raise Errors::NotFoundError.new(message: error_message)
    end

    if @courses.empty?
      raise Errors::BaseError.new(message: "Please select at least 1 course", status: 400)
    end

    if @courses.any? { |course| course.test? }
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end
  end

  def instruction_params
    params.permit(:trivia_id, :courses => [])
  end

  def update_session_params
    params.permit(:current_question_number, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end
end
