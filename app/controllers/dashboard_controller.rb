class DashboardController < ApplicationController
  skip_before_action :authorize!, only: [:carousel]

  wrap_parameters format: []

  def carousel
    render json: {
      data: [
        # {
        #   image: "link to image",
        #   link: "#{ENV['HOST_URL']}"
        # }
      ]
    }
  end
end
