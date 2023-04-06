class QuestionsController < ApplicationController
  include SessionHelper
  include TestHelper

  before_action :load_creators_course, except: [:index, :explanation]
  before_action :load_question, only: [:show, :update, :publish, :destroy]
  before_action :published_test_check, only: [:create, :update, :publish, :destroy]

  wrap_parameters format: []

  def index
    # Not using non_deleted_courses here due to the possibility
    # of a creator deleting a course while a user is taking its session.
    # Todo: Reconsider this later
    @course = Course.find(params[:course_id])

    if @course.test?
      handle_test_index
    else
      handle_course_index
    end
  end

  def explanation
    question = Question.find(params[:question_id])
    course = question.course

    if course.sale_status_explanations?
      if current_user.has_purchased_item(course)
        explanation = question.explanation
        explanation_image_url = question.generated_explanation_image_url
      else
        explanation = "Please purchase these explanations to view them."
        explanation_image_url = nil
      end
    else
      explanation = question.explanation
      explanation_image_url = question.generated_explanation_image_url
    end

    render json: {
      data: {
        question_id: question.id,
        explanation: explanation,
        explanation_image_url: explanation_image_url,
      }
    }
  end

  # From a Creator's point of view

  def questions
    # Custom pagination for find_by_sql
    total_questions = @course.questions.non_deleted_questions.count
    limit, offset, paginated_metadata = custom_paginate(total_questions, params)

    # Recursive CTE to get questions in order
    cte_query = <<-SQL
    WITH RECURSIVE ordered_questions AS (
      SELECT * FROM questions
      WHERE course_id = ?
      AND previous_id IS NULL

      UNION ALL

      SELECT q.* FROM questions q
      INNER JOIN ordered_questions oq ON q.previous_id = oq.id
    )
    SELECT * FROM ordered_questions LIMIT ? OFFSET ?
    SQL

    questions = Question.find_by_sql([cte_query, @course.id, limit, offset])

    render json: { data: questions.map do |question|
      question.serialized_creator_question_list_item[:question]
    end
    }.merge(paginated_metadata)

  end

  def show
    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def create
    draft = create_draft(create_question_params)
    question = @course.questions.build
    question.draft = draft

    # Attach images
    question.question_image_draft.attach(create_question_params[:question_image]) if create_question_params.key?(:question_image)
    question.explanation_image_draft.attach(create_question_params[:explanation_image]) if create_question_params.key?(:explanation_image)

    # Add generated urls to draft json
    question.draft["question_image_url"] = generated_attachment_url(question.question_image_draft) if question.question_image_draft.attached?
    question.draft["explanation_image_url"] = generated_attachment_url(question.explanation_image_draft) if question.explanation_image_draft.attached?

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

    draft = create_draft(update_question_params)
    @question.draft = draft

    # Attach draft images
    handle_image_update(update_question_params, :question_image, :question_image_url)
    handle_image_update(update_question_params, :explanation_image, :explanation_image_url)

    # Add generated urls to draft json
    @question.draft["question_image_url"] = generated_attachment_url(@question.question_image_draft)
    @question.draft["explanation_image_url"] = generated_attachment_url(@question.explanation_image_draft)

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
      @question.question_raw = draft[:question_raw]

      @question.explanation = draft[:explanation]
      @question.explanation_raw = draft[:explanation_raw]

      @question.options = draft[:options]
      @question.answer = draft[:answer]
      @question.multiplier = draft[:multiplier]
      @question.multi_answer = draft[:multi_answer]

      @question.version = @question.version + 1
      @question.draft = nil
      @question.publish_status = :publish_status_published

      @question.save!

      # Handle images if save was successful

      # Transfer images if present in draft, detach otherwise as published image state should exactly mirror draft
      if @question.question_image_draft.attached?
        copy_attachment(@question.question_image_draft, @question.question_image)
      else
        @question.question_image.detach
      end

      if @question.explanation_image_draft.attached?
        copy_attachment(@question.explanation_image_draft, @question.explanation_image)
      else
        @question.explanation_image.detach
      end

      @question.question_image_draft.purge_later
      @question.explanation_image_draft.purge_later

      # TODO: Move previous version to version history when implemented

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
        # Also delete any drafts if soft-deleting
        @question.draft = nil
        @question.question_image_draft.purge_later
        @question.explanation_image_draft.purge_later

        @question.question_status_deleted!
      rescue
        raise Errors::InvalidError.new(@question.errors.to_h)
      end
    end

    render json: { message: "Deleted successfully", data: {} }, status: 200
  end

  private

  def load_creators_course
    @course = Course.non_deleted_courses.find(params[:course_id])
    if @course.creator != current_user
      raise Errors::ForbiddenError.new(message: "You don't have the authority to manage questions in this course.")
    end
  end

  def load_question
    begin
      @question = @course.questions.non_deleted_questions.find(params[:id])
    rescue
      raise Errors::NotFoundError.new(message: "Cannot find this question in the course")
    end
  end

  def handle_course_index
    session_type = require_session_type(params[:session_type])

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

    # Attach the image files in the create/update methods instead
    question = @course.questions.build(
      question_params.except(
        :question_image, :question_image_url, :explanation_image, :explanation_image_url, :option_images
      )
    )

    rough_draft = question.as_json

    return strip_non_draft_fields(rough_draft)
  end

  # Image handling in controller during update
  # 1.) image √   image_url √   =>    Changing image
  # 2.) image √   image_url X   =>    New image
  # 3.) image X   image_url √   =>    No changes
  # 4.) image X   image_url X   =>    Deleting image
  def handle_image_update(question_params, image_key, image_url_key)
    has_image_to_upload = question_params[image_key].present?
    has_image_url_to_retain = question_params[image_url_key].present?

    draft_attachment, attachment = get_attachments(image_key)

    if has_image_to_upload
      # Attach new or changed image, active storage would purge any current image first
      draft_attachment.attach(update_question_params[image_key]) if draft_attachment.present?
    else
      if has_image_url_to_retain
        # Attach the latest image to this draft
        if draft_attachment.attached?
          # Do nothing, latest draft image already attached
        elsif attachment.attached?
          # Transfer a copy of the published attachment to the draft
          copy_attachment(attachment, draft_attachment)
        end
      else
        # Delete image
        draft_attachment.purge if draft_attachment.present?
      end
    end
  end

  def get_attachments(image_key)
    case image_key
    when :question_image
      return @question.question_image_draft, @question.question_image
    when :explanation_image
      return @question.explanation_image_draft, @question.explanation_image
    else
      return nil, nil
    end
  end

  def copy_attachment(from_attachment, to_attachment)
    to_attachment.attach(
      io: StringIO.new(from_attachment.download),
      filename: from_attachment.filename,
      content_type: from_attachment.content_type
    )
  end

  def generated_attachment_url(attachment)
    begin
      path = rails_blob_path(attachment, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
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

  def create_question_params
    params.permit(:question, :question_raw, :question_image,
                  :explanation, :explanation_raw, :explanation_image,
                  :options, :answer, :multi_answer, :multiplier, :option_images
    )
  end

  def update_question_params
    params.permit(:question, :question_raw, :question_image, :question_image_url,
                  :explanation, :explanation_raw, :explanation_image, :explanation_image_url,
                  :options, :answer, :multi_answer, :multiplier, :option_images
    )
  end
end
