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

    # Currently, course bundles are required to create a trivia set, not just plain course ids
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

  def submissions
    trivia = TriviaSet.non_deleted_trivia.find(params[:trivia_set_id])

    if current_user != trivia.creator
      raise Errors::ForbiddenError.new(message: "You don't have the authority to view these test submissions")
    end

    submissions = trivia.results.order(created_at: :desc)
    paginated_submissions = paginate(submissions, params)

    render json: paginated_submissions,
           root: :data,
           meta: paginated_meta(paginated_submissions),
           each_serializer: ProfileResultSerializer,
           status: :ok
  end

  def leaderboard
    trivia = TriviaSet.non_deleted_trivia.find(params[:trivia_set_id])

    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    user_count = trivia.results.distinct.count(:user_id)
    closing_time = trivia.expiration + (trivia.rules['time']).seconds + lag_time

    # Get first result that isn't disqualified (if any) or the first result (if all are disqualified)
    results = trivia.results.where(user: current_user)&.order(score: :desc, elapsed_time: :asc, created_at: :asc)
    result = results&.to_a&.find { |r| !r.disqualified? } || results&.first

    score = result&.score
    disqualified = result&.disqualified? || false

    # Return empty rankings to unauthorised users who want to view the leaderboard before the trivia is closed
    if !trivia.trivia_status_closed? && current_user != trivia.creator
      _, _, paginated_metadata = custom_paginate(0, params)
      render json:
               {
                 data: {
                   has_result: !score.nil?,
                   position: nil,
                   score: score,
                   total: result&.total,
                   extra_id: result&.extra_id,
                   disqualified: disqualified,
                   users: user_count,
                   closing_time: closing_time,
                   rankings: []
                 }
               }.merge(paginated_metadata),
             status: :ok
      return
    end

    position = get_ranked_position(trivia, current_user)

    top_submissions = trivia.results.order(score: :desc, elapsed_time: :asc, created_at: :asc)
    paginated_submissions = paginate(top_submissions, params)

    render json:
             {
               data: {
                 has_result: !score.nil?,
                 position: disqualified ? nil : position,
                 score: score,
                 total: result&.total,
                 extra_id: result&.extra_id,
                 disqualified: disqualified,
                 users: user_count,
                 closing_time: closing_time,
                 rankings: paginated_submissions.map do |ranked_result|
                   ranked_result.serialized_profile_result
                 end
               },
             }.merge(paginated_meta(paginated_submissions)),
           status: :ok
  end

  def invite_users
    trivia_set = TriviaSet.non_deleted_trivia.find(params[:trivia_set_id])

    # Check if user has permission to invite
    if current_user != trivia_set.creator || current_user.user_type == :admin
      raise Errors::ForbiddenError.new(message: "You don't have the authority to invite users to this trivia")
    end

    # Check if trivia is invite-only
    unless trivia_set.invite_only?
      raise Errors::BaseError.new(message: "This trivia is not set to invite-only", status: 400)
    end

    emails = invite_user_params[:emails] || []

    # Validate email limit (100 max)
    existing_invitations_count = trivia_set.trivia_invitations.count
    if existing_invitations_count + emails.length > 100
      raise Errors::BaseError.new(message: "Cannot exceed 100 invitations per trivia", status: 400)
    end

    successful_invites = []
    failed_invites = []

    emails.each do |email|
      begin
        # Check if invitation already exists
        if trivia_set.trivia_invitations.exists?(email: email)
          failed_invites << { email: email, reason: "Already invited" }
          next
        end

        # Create invitation
        invitation = trivia_set.trivia_invitations.create!(
          email: email,
          invited_by: current_user,
          user: User.find_by(email: email) # Link user if they exist
        )

        successful_invites << invitation
      rescue ActiveRecord::RecordInvalid => e
        failed_invites << { email: email, reason: e.message }
      end
    end

    # TODO: Send invitation emails here
    # InvitationMailer.with(invitations: successful_invites, trivia_set: trivia_set).send_invitations.deliver_later

    message = ""
    success_count = successful_invites.length
    failure_count = failed_invites.length

    if success_count > 0
      message += "Sent #{success_count} #{'invitation'.pluralize(success_count)} successfully. "
    end

    if failure_count > 0
      message += "#{failure_count} #{'invitation'.pluralize(failure_count)} failed to send."

      if success_count == 0
        raise Errors::BaseError.new(message: message, status: 400)
      end
    end

    if message.blank?
      message = "No invitations were sent."
    end

    render json: {
      data: {
        successful_invites: successful_invites.map(&:email)
      },
      message: message,
    }
  end

  private

  def get_ranked_position(trivia, user)
    # Todo: Update the disqualification logic here too to use a list of disqualified results
    #  For now, disqualified results are not going to exist
    ranked_results_sql = <<~SQL
      SELECT id, user_id, RANK() OVER (ORDER BY score DESC, elapsed_time ASC, created_at ASC) as rank
      FROM results
      WHERE trivia_set_id = ?
    SQL
    # WHERE trivia_set_id = ? AND (extra_id IS NOT NULL AND extra_id NOT LIKE '%Disqualified')

    user_rank_sql = <<~SQL
      SELECT rank
      FROM (#{ranked_results_sql}) as ranked_results
      WHERE user_id = ?
      LIMIT 1
    SQL

    user_rank = Result.find_by_sql([user_rank_sql, trivia.id, user.id]).first&.rank

    return user_rank
  end

  def create_trivia_set_params
    params.permit(:title, :subtitle, :rules, :expiration, :private, :course_bundles)
  end

  def invite_user_params
    params.permit(:emails => [])
  end
end
