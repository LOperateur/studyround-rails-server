class DashboardController < ApplicationController
  skip_before_action :authorize!, only: [:carousel]

  wrap_parameters format: []

  def carousel
    render json: {
      data: [
        {
          image: ActionController::Base.helpers.asset_path("carousel/carousel-1.jpg"),
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: ActionController::Base.helpers.asset_path("carousel/carousel-2.jpg"),
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: ActionController::Base.helpers.asset_path("carousel/carousel-3.jpg"),
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: ActionController::Base.helpers.asset_path("carousel/carousel-4.jpg"),
          link: "https://u-learn-web.herokuapp.com"
        }
      ]
    }
  end
end
