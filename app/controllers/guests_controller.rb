class GuestsController < ApplicationController
  skip_before_action :authorize!, only: [:create, :invite, :demo_report]

  wrap_parameters format: []

  def create
    guest = Guest.new
    guest.save!

    render json: guest, root: :data, status: :created
  end

  def invite
    # TODO: Move this to a shared concern
    guest_id = params[:guest_id] # This is the guest_id from the URL params (or from the end_demo params)
    guest = Guest.find(guest_id)

    email = invite_guest_params[:email]
    score = "#{guest.result['score']}/#{guest.result['total']}"

    # Still check if the provided email is a user
    if User.exists?(email: email)
      raise Errors::BaseError.new(
        message: "This email is already associated with a StudyRound account",
        action: :login,
        status: 400
      )
    end

    guest.update!(email: email)

    # Get courses from multi course ids
    courses = Course.select("title").where(id: guest.result['multi_course_ids'])

    pass_token = JsonWebToken.encode({ guest_id: guest_id }, 30.days.from_now)

    ResultMailer.with(
      email: email,
      score: score,
      title: courses.map(&:title).join(', '),
      pass_token: pass_token
    ).demo_result_signup_email.deliver_later

    render json: guest, root: :data, status: :ok, meta: { message: "Emailed results to #{email}!" }
  end

  def demo_report
    guest = Guest.find(params[:guest_id])

    if guest.result.blank? || guest.result['session_items'].blank?
      raise Errors::BaseError.new(message: "No result data available for report generation", status: 400)
    end

    # Idempotency: return existing report
    if guest.result['report_content'].present?
      render json: { data: { report_content: guest.result['report_content'] } }, status: :ok
      return
    end

    # Build a temporary Result object from the guest's JSONB data
    result_data = guest.result
    temp_result = Result.new(
      score: result_data['score'],
      total: result_data['total'],
      duration: result_data['duration'],
      elapsed_time: result_data['elapsed_time'],
      session_type: result_data['session_type'],
      session_items: result_data['session_items'],
      num_questions: result_data['num_questions'],
    )

    service = OpenaiReportService.new(temp_result)
    response = service.generate

    if response[:error]
      raise Errors::BaseError.new(message: "Failed to generate report: #{response[:error]}", status: 500)
    end

    # Store the report in the guest's result JSONB
    updated_result = guest.result.merge('report_content' => response[:report])
    guest.update!(result: updated_result)

    render json: { data: { report_content: response[:report] } }, status: :ok
  end

  private

  def invite_guest_params
    params.permit(:email)
  end
end
