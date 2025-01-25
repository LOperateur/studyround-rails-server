class GuestsController < ApplicationController
  skip_before_action :authorize!, only: [:create, :invite]

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

  private

  def invite_guest_params
    params.permit(:email)
  end
end
