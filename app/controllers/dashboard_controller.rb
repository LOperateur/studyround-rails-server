class DashboardController < ApplicationController
  skip_before_action :authorize!, only: [:carousel]

  wrap_parameters format: []

  def carousel
    render json: {
      data: [
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-1.jpg",
          link: "#{ENV['HOST_URL']}"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-2.jpg",
          link: "#{ENV['HOST_URL']}"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-3.jpg",
          link: "#{ENV['HOST_URL']}"
        },
        {
          image: "https://ulearn-backend-assets-staging.s3.amazonaws.com/assets/carousel-4.jpg",
          link: "#{ENV['HOST_URL']}"
        }
      ]
    }
  end
end
