class DashboardController < ApplicationController
  skip_before_action :authorize!, only: [:carousel]

  wrap_parameters format: []

  def carousel
    render json: {
      data: [
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-1.jpg",
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-2.jpg",
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-3.jpg",
          link: "https://u-learn-web.herokuapp.com"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-4.jpg",
          link: "https://u-learn-web.herokuapp.com"
        }
      ]
    }
  end
end
