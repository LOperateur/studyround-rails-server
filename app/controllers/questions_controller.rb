class QuestionsController < ApplicationController
  include SessionHelper
  include TestHelper

  before_action :load_course_and_verify, except: [:index, :explanation]
  before_action :load_question, only: [:show, :update, :publish, :destroy]
  before_action :published_test_check, only: [:create, :update, :publish, :destroy]

  wrap_parameters format: []

  def index
    @course = Course.find(params[:course_id])

    if @course.test?
      handle_test_index
    else
      handle_course_index
    end
  end

  def explanation
    question = Question.find(params[:question_id])
    render json: {
      data: {
        question_id: question.id,
        explanation: question.explanation,
        explanation_image_url: question.explanation_image_url,
      }
    }
  end

  # From a Creator's point of view

  def questions
    questions = @course.questions.non_deleted_questions
    paginated_questions = paginate(questions, params)

    render json: paginated_questions, root: :data, meta: paginated_meta(paginated_questions), each_serializer: CreatorQuestionListSerializer
  end

  def show
    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def create
    draft = create_draft(create_update_question_params)
    question = @course.questions.build
    question.draft = draft

    begin
      question.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(question.errors.to_h)
    end

    render json: question, root: :data, serializer: CreatorQuestionSerializer
  end

  def update
    if @question.version == 6
      raise Errors::BaseError.new(message: "You can only edit a question a maximum of 5 times", status: 400)
    end

    draft = create_draft(create_update_question_params)
    @question.draft = draft

    begin
      @question.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(@question.errors.to_h)
    end

    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def publish
    if @question.draft.nil?
      if @question.publish_status_published?
        raise Errors::BaseError.new(message: "The latest content of this question is already published", status: 400)
      else
        raise Errors::BaseError.new(message: "There's no content to publish", status: 400)
      end
    end

    draft = @question.draft.symbolize_keys

    begin
      @question.question = draft[:question]
      @question.question_image_url = draft[:question_image_url]
      @question.question_raw = draft[:question_raw]

      @question.explanation = draft[:explanation]
      @question.explanation_image_url = draft[:explanation_image_url]
      @question.explanation_raw = draft[:explanation_raw]

      @question.options = draft[:options]
      @question.answer = draft[:answer]
      @question.multiplier = draft[:multiplier]
      @question.multi_answer = draft[:multi_answer]

      @question.version = @question.version + 1
      @question.draft = nil
      @question.publish_status = :publish_status_published

      # TODO: Move previous version to version history when implemented

      @question.save!
    rescue
      raise Errors::InvalidError.new(@question.errors.to_h)
    end

    render json: @question, root: :data, meta: { message: "Published successfully" },
           serializer: CreatorQuestionSerializer
  end

  def destroy
    # If Question has never been published, hard delete it
    if @question.question.nil?
      @question.destroy!
    else
      begin
        @question.question_status_deleted!
      rescue
        raise Errors::InvalidError.new(@question.errors.to_h)
      end
    end

    render json: { message: "Deleted successfully", data: {} }, status: 200
  end

  private

  def load_course_and_verify
    @course = Course.find(params[:course_id])
    if @course.creator != current_user
      Errors::ForbiddenError.new(message: "You don't have the authority to manage questions in this course.")
    end
  end

  def load_question
    begin
      @question = @course.questions.non_deleted_questions.find(params[:id])
    rescue
      raise Errors::NotFoundError.new(message: "Cannot find question with id #{params[:id]} for course with id #{params[:course_id]}")
    end
  end

  def handle_course_index
    session_type = session_type(params[:session_type])

    case session_type
    when :study
      questions = @course.questions.publish_status_published.order(created_at: :asc)
    when :quiz, :practice
      session = Session.find(params[:session_id])
      question_ids = session.session_items.map { |session_item| session_item["question_id"] }

      # Sort by the order of ids supplied
      questions = Question.where(id: question_ids).sort_by { |i| question_ids.index(i.id) }
    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end

    paginated_questions = paginate(questions, params)
    render json: paginated_questions, root: :data, each_serializer: QuestionAnswerSerializer, meta: paginated_meta(paginated_questions)
  end

  def handle_test_index
    session_param = get_start_test_session(current_user, @course)

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # Existing session, simply assign it
    session = session_param

    # If session doesn't have an id, then it doesn't exist in the DB yet.
    if !session[:id].present?
      raise Errors::BaseError.new(message: "No existing session for this user. Please refresh or check your results", status: 400)
    end

    questions = @course.questions.publish_status_published.order(created_at: :asc)

    paginated_questions = paginate(questions, params)
    render json: paginated_questions, root: :data, meta: paginated_meta(paginated_questions)
  end

  def raise_ended_test_error(course)
    # Calculate and return result in the data of the surfaced error
    result = get_end_test_result(
      current_user,
      course,
    ).serialized_result

    raise Errors::ForbiddenError.new(
      message: "Time up! Submitting session...",
      action: :submit,
      data: result[:result]
    )
  end

  def create_draft(question_params)
    if question_params.key?(:options)
      options_json = JSON.parse(question_params[:options])
      question_params[:options] = options_json
    end

    if question_params.key?(:question_raw)
      question_raw_json = JSON.parse(question_params[:question_raw])
      question_params[:question_raw] = question_raw_json
    end

    if question_params.key?(:explanation_raw)
      explanation_raw_json = JSON.parse(question_params[:explanation_raw])
      question_params[:explanation_raw] = explanation_raw_json
    end

    if question_params.key?(:answer)
      answer_json = JSON.parse(question_params[:answer])
      question_params[:answer] = answer_json
    end

    # Upload actual image files if they are present, they override the url values
    # But exclude them from the actual question object
    # TODO: Revisit this exclusion to exclude urls instead
    question = @course.questions.build(question_params.except(:question_image, :explanation_image, :option_images))

    draft = question.as_json
    return strip_non_draft_fields(draft)
  end

  def published_test_check
    if @course.test?
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot make question changes within a published Test!")
      end
    end
  end

  def strip_non_draft_fields(draft)
    return draft.symbolize_keys.except(:id, :course_id, :order, :tags, :version, :publish_status,
                                       :question_status, :draft, :created_at, :updated_at)
  end

  def create_update_question_params
    params.permit(:question, :question_raw, :question_image, :question_image_url,
                  :explanation, :explanation_raw, :explanation_image, :explanation_image_url,
                  :options, :answer, :multi_answer, :multiplier, :option_images
    )
  end
end
