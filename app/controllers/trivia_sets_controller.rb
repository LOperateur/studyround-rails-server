class TriviaSetsController < ApplicationController
  include ActionView::Helpers::DateHelper
  include TriviaHelper

  wrap_parameters format: []

  def index
    trivia_sets = paginate(TriviaSet.non_deleted_trivia.all.order(created_at: :desc), params)
    render json: trivia_sets, root: :data, meta: paginated_meta(trivia_sets)
  end

  def show
    trivia_set = TriviaSet.non_deleted_trivia.find(params[:id])
    render json: trivia_set, root: :data
  end

  def create
    trivia_set = TriviaSet.new(create_trivia_set_params.except(:rules, :course_bundles))
    trivia_set.creator = current_user

    if create_trivia_set_params.key?(:rules)
      rules_json = JSON.parse(create_trivia_set_params[:rules])
      trivia_set.rules = rules_json
    end

    if create_trivia_set_params.key?(:course_bundles)
      course_bundles_json = JSON.parse(create_trivia_set_params[:course_bundles])
      trivia_set.course_bundle_ids = course_bundles_json
    end

    trivia_set.save!
    render json: trivia_set, root: :data, status: :created
  end

  def update
    trivia_set = TriviaSet.non_deleted_trivia.find(params[:id])

    if current_user != trivia_set.creator
      raise Errors::ForbiddenError.new(message: "You don't have the authority to update this Trivia")
    end

    if create_trivia_set_params.key?(:rules)
      rules_json = JSON.parse(create_trivia_set_params[:rules])
      trivia_set.rules = rules_json
    end

    if create_trivia_set_params.key?(:course_bundles)
      course_bundles_json = JSON.parse(create_trivia_set_params[:course_bundles])
      trivia_set.course_bundle_ids = course_bundles_json
    end

    trivia_set.update!(create_trivia_set_params.except(:rules, :course_bundles))
    render json: trivia_set, root: :data
  end

  def delete
    trivia_set = TriviaSet.non_deleted_trivia.find(params[:trivia_set_id])

    if current_user != trivia_set.creator
      raise Errors::ForbiddenError.new(message: "You don't have the authority to delete this Trivia")
    end

    trivia_set.trivia_status_deleted!
    render json: trivia_set, root: :data, meta: { message: "Trivia is now Deleted!" }
  end

  def close
    trivia = TriviaSet.non_deleted_trivia.find(params[:trivia_set_id])

    if current_user != trivia.creator
      raise Errors::ForbiddenError.new(message: "You don't have the authority to close this Trivia")
    end

    # Confirm that the lag time is exceeded and the test is closeable
    expiration = trivia.expiration
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (trivia.rules['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    time_left = distance_of_time_in_words(closing_time, Time.now)
    if !is_closeable
      raise Errors::BaseError.new(message: "Please wait #{time_left} before you can close this test", status: 400)
    end

    # Submit all remaining sessions
    trivia.sessions.each do |session|
      begin
        get_end_trivia_result(session.user, session.trivia_set)
      rescue Errors::BaseError
        # Ignored
      end
    end

    # Close the test
    trivia.trivia_status_closed!

    # Send an email to all trivia participants
    TriviaResultsEmailSendJob.perform_later(trivia)

    render json: trivia, meta: { message: "Trivia is now Closed!" }, root: :data
  end

  private

  def create_trivia_set_params
    params.permit(:title, :subtitle, :rules, :expiration, :private, :course_bundles)
  end
end
