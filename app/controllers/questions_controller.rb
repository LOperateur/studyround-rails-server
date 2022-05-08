class QuestionsController < ApplicationController
  skip_before_action :authorize!, only: [:index, :show]

  wrap_parameters format: []

  def index

    end

  def show

  end
end
