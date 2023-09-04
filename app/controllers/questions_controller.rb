class QuestionsController < ApplicationController
  include SessionHelper
  include TestHelper

  before_action :load_creators_course, except: [:index, :explanation]
  before_action :load_question, only: [:show, :update, :publish, :destroy, :add_note, :remove_note, :resolve_notes]
  before_action :published_test_check, only: [:create, :update, :publish, :destroy]
  before_action :check_admin, only: [:resolve_notes, :bulk_import_questions_json]

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

    if course.sale_status_explanations? && !current_user.has_purchased_item(course)
      explanation = "Please purchase these explanations to view them."
      explanation_image_url = nil
      explanation_image_asset = nil
    else
      explanation = question.explanation
      explanation_image_url = question.generated_explanation_image_url
      explanation_image_asset = question.explanation_image_asset
    end

    render json: {
      data: {
        question_id: question.id,
        explanation: explanation,
        explanation_image_url: explanation_image_url,
        explanation_image_asset: explanation_image_asset,
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
    SELECT * FROM ordered_questions 
    WHERE NOT question_status = 3 LIMIT ? OFFSET ?
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

    # Todo: deprecated - Remove direct question image attachments
    # Attach images
    question.question_image_draft.attach(create_question_params[:question_image]) if create_question_params.key?(:question_image)
    question.explanation_image_draft.attach(create_question_params[:explanation_image]) if create_question_params.key?(:explanation_image)

    # Todo: deprecated - Remove direct question image attachments
    # Add generated urls to draft json
    question.draft["question_image_url"] = generated_attachment_url(question.question_image_draft) if question.question_image_draft.attached?
    question.draft["explanation_image_url"] = generated_attachment_url(question.explanation_image_draft) if question.explanation_image_draft.attached?

    # Identify the original creator for notes
    question.creator_id = current_user.id

    Question.transaction do
      # Reference Assets and save the question
      build_asset_references(question)
      establish_position_and_save(question, create_question_params[:position])
    end

    render json: question, root: :data, serializer: CreatorQuestionSerializer
  end

  def update
    if @question.version == 6
      raise Errors::BaseError.new(message: "You can only edit a question a maximum of 5 times", status: 400)
    end

    draft = create_draft(update_question_params)
    @question.draft = draft

    # Todo: deprecated - Remove direct question image attachments
    # Attach draft images
    handle_image_update(update_question_params, :question_image, :question_image_url)
    handle_image_update(update_question_params, :explanation_image, :explanation_image_url)

    # Todo: deprecated - Remove direct question image attachments
    # Add generated urls to draft json
    @question.draft["question_image_url"] = generated_attachment_url(@question.question_image_draft)
    @question.draft["explanation_image_url"] = generated_attachment_url(@question.explanation_image_draft)

    Question.transaction do
      # Reference Assets and update the question
      build_asset_references(@question)
      @question.save!
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

    # Handle the publishing
    publish_question @question

    # Todo: deprecated - Remove direct question image attachments
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

    render json: @question, root: :data, meta: { message: "Published successfully" },
           serializer: CreatorQuestionSerializer
  end

  def destroy
    Question.transaction do
      # Adjacent question updates
      @question.remove_linked_self_references

      # If Question has never been published, hard delete it
      if @question.question.nil?
        @question.destroy!
      else
        # Also delete any drafts if soft-deleting
        @question.draft = nil
        @question.question_image_draft.purge_later
        @question.explanation_image_draft.purge_later

        @question.previous_id = nil
        @question.next_id = nil

        @question.question_status_deleted!
      end
    end

    render json: { message: "Deleted successfully", data: {} }, status: 200
  end

  # Question Notes implementation

  def add_note
    note = @question.notes
    if note.present?
      note[current_user.username] = create_note_params[:note]
    else
      note = { current_user.username => create_note_params[:note] }
    end

    @question.notes = note
    @question.save!

    render json: @question, root: :data, meta: { message: "Note Added" }, serializer: CreatorQuestionSerializer
  end

  def remove_note
    note = @question.notes
    if note.present?
      # Remove the note with the current user's username
      note.delete(current_user.username)

      # If there are no more notes, set notes to nil
      if note.empty?
        note = nil
      end
    end

    @question.notes = note
    @question.save!

    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def resolve_notes
    # Just delete all notes
    @question.notes = nil
    @question.save!

    render json: @question, root: :data, meta: { message: "All Notes Resolved!" }, serializer: CreatorQuestionSerializer
  end

  def publish_questions
    if @course.test?
      if @course.publish_status_published?
        raise Errors::ForbiddenError.new(message: "You cannot make question changes within a published Test!")
      end
    end

    message = ""
    publish_success_count = 0
    publish_errors_count = 0

    # Publish all the valid questions in the course
    @course.questions.each do |question|
      if question.draft.present?
        begin
          publish_question question
          publish_success_count += 1
        rescue
          publish_errors_count += 1
        end
      end
    end

    if publish_success_count > 0
      message += "Published #{publish_success_count} #{'question'.pluralize(publish_success_count)}. "
    end

    if publish_errors_count > 0
      message += "#{publish_errors_count} #{'question'.pluralize(publish_errors_count)} failed to publish."

      # If all questions failed to publish, throw an error instead
      if publish_success_count == 0
        raise Errors::BaseError.new(message: message, status: 400)
      end
    end

    if message.blank?
      message = "No draft questions to publish"
    end

    render json: { message: message }, status: :ok
  end

  def bulk_set_source
    # Source can be nil but if it is blank, we still want to set it to nil
    source = bulk_set_source_params[:source].presence

    @course.questions.non_deleted_questions.update_all(source: source)
    render json: @course, meta: { message: "Question sources updated" }, root: :data, serializer: CreatorCourseSerializer
  end

  def bulk_set_year
    # Year can be nil but if it is blank, we still want to set it to nil
    year = bulk_set_year_params[:year].presence

    @course.questions.non_deleted_questions.update_all(year: year)
    render json: @course, meta: { message: "Question years updated" }, root: :data, serializer: CreatorCourseSerializer
  end

  def bulk_import_questions_json
    count = 0

    Question.transaction do
      # Fetch the JSON from the file upload
      questions_json = JSON.parse(bulk_import_questions_params[:questions_json].read)

      # Check if the questions_json is an array
      if questions_json.kind_of?(Array)
        # Iterate through the questions_json array
        questions_json.each do |json|
          question = @course.questions.build
          question.draft = json
          question.creator_id = current_user.id

          establish_position_and_save(question, nil)
        end
      else
        raise Errors::BaseError.new(message: "Invalid questions JSON", status: 400)
      end

      count = questions_json.count
    end

    render json: { message: "Imported #{count} Questions Successfully", data: {} }, status: :created
  end

  private

  def load_creators_course
    @course = Course.non_deleted_courses.find(params[:course_id])
    if @course.creator != current_user && current_user.user_type != :admin
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
      questions, paginated_metadata = published_active_ordered_questions(@course, params)
      render json: { data: questions.map do |question|
        question.serialized_question_with_answer[:question]
      end
      }.merge(paginated_metadata)
      return # Return early to prevent double render
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

    questions, paginated_metadata = published_active_ordered_questions(@course, params)
    render json: { data: questions.map do |question|
      question.serialized_question[:question]
    end
    }.merge(paginated_metadata)
  end

  def establish_position_and_save(question, position)
    Question.transaction do
      if position.nil? || position.to_i < 0
        # Question position is not specified, so we will use the last
        # question's position which has a next_id of nil. This could be nil
        last_question = @course.questions.non_deleted_questions.find_by(next_id: nil)

        question.previous_id = last_question&.id
        question.save!

        if last_question.present?
          last_question.next_id = question.id
          last_question.save!
        end
      else
        if position.to_i > @course.questions.non_deleted_questions.count - 1
          raise Errors::BaseError.new(message: "Invalid insert position", status: 400)
        end

        # Find the target question based on the specified position
        position_query = <<-SQL
        WITH RECURSIVE question_position AS (
          SELECT *, 0 AS position
          FROM questions
          WHERE previous_id IS NULL AND course_id = ?
    
          UNION ALL
    
          SELECT q.*, qp.position + 1
          FROM questions q
          INNER JOIN question_position qp ON q.previous_id = qp.id
        )
        SELECT * FROM question_position 
        WHERE position = ?
        AND NOT question_status = 3
        SQL

        target_question = Question.find_by_sql([position_query, @course.id, position]).first

        # Now we have the target question, we can set the next and previous pointers
        # The question will be inserted before the target question
        question.next_id = target_question&.id
        question.previous_id = target_question&.previous_id
        question.save!

        if target_question.present?
          target_question.previous_id = question.id
          target_question.save!
        end

        if question.previous.present?
          question.previous.next_id = question.id
          question.previous.save!
        end
      end
    end
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

    # Attach the assets in the create/update methods instead
    # Position and next/previous id's have no relevance in the draft JSON
    question = @course.questions.build(
      question_params.except(
        :question_image, :question_image_url, :explanation_image,
        :explanation_image_url, :option_images, :position,
        :question_image_asset_id, :explanation_image_asset_id, :passage_asset_id,
      )
    )

    rough_draft = question.as_json

    # Indicate the Asset ID's for the draft
    rough_draft["question_image_asset_id"] = question_params[:question_image_asset_id] if update_question_params.key?(:question_image_asset_id)
    rough_draft["explanation_image_asset_id"] = question_params[:explanation_image_asset_id] if update_question_params.key?(:explanation_image_asset_id)
    rough_draft["passage_asset_id"] = question_params[:passage_asset_id] if update_question_params.key?(:passage_asset_id)

    return strip_non_draft_fields(rough_draft)
  end

  # Publish the question while ignoring deprecated image fields
  def publish_question(question)
    draft = question.draft.symbolize_keys

    question.question = draft[:question]
    question.question_raw = draft[:question_raw]

    question.explanation = draft[:explanation]
    question.explanation_raw = draft[:explanation_raw]

    question.options = draft[:options]
    question.answer = draft[:answer]
    question.multiplier = draft[:multiplier]
    question.multi_answer = draft[:multi_answer]
    question.year = draft[:year]

    question.version = question.version + 1
    question.draft = nil
    question.publish_status = :publish_status_published

    Question.transaction do
      publish_asset_references(question)
      question.save!
    end
  end

  def build_asset_references(question)
    # Handle the assets if they are present in the request parameters.
    # Ideally, when building references, the params should always have the assets id's
    # regardless of whether they are being updated or not.

    if question.draft.key?("question_image_asset_id")
      # Delete the old reference if it exists
      reference_type = :reference_type_question_image_draft
      question.question_asset_references.where(reference_type: reference_type).destroy_all

      if question.draft["question_image_asset_id"].present?
        question.question_asset_references.build(
          question_asset_id: question.draft["question_image_asset_id"],
          reference_type: reference_type,
        )
      end
    end

    if question.draft.key?("explanation_image_asset_id")
      # Delete the old reference if it exists
      reference_type = :reference_type_explanation_image_draft
      question.question_asset_references.where(reference_type: reference_type).destroy_all

      if question.draft["explanation_image_asset_id"].present?
        question.question_asset_references.build(
          question_asset_id: question.draft["explanation_image_asset_id"],
          reference_type: reference_type,
        )
      end
    end

    if question.draft.key?("passage_asset_id")
      # Delete the old reference if it exists
      reference_type = :reference_type_passage_draft
      question.question_asset_references.where(reference_type: reference_type).destroy_all

      if question.draft["passage_asset_id"].present?
        question.question_asset_references.build(
          question_asset_id: question.draft["passage_asset_id"],
          reference_type: reference_type,
        )
      end
    end

    # Option image assets are handled differently as they are nested in the options JSON
    # Delete all old options references if any exists
    reference_type = :reference_type_option_image_draft
    question.question_asset_references.where(reference_type: reference_type).destroy_all

    # Build the new references for the options, if any options are present
    question.draft["options"]&.each do |option|
      if option["option_image_asset_id"].present?
        question.question_asset_references.build(
          question_asset_id: option["option_image_asset_id"],
          reference_type: reference_type,
        )
      end
    end
  end

  def publish_asset_references(question)
    # Remove all previously published references
    # Todo: Check if they are different from the draft references to avoid unnecessary DB calls
    # Only make this call if there are any assets referenced by the question
    if question.question_assets.exists?
      question.question_asset_references.where(reference_type: :reference_type_question_image).destroy_all
      question.question_asset_references.where(reference_type: :reference_type_explanation_image).destroy_all
      question.question_asset_references.where(reference_type: :reference_type_option_image).destroy_all
      question.question_asset_references.where(reference_type: :reference_type_passage).destroy_all
    end

    # Change the reference types from draft to published
    question.question_asset_references.where(reference_type: :reference_type_question_image_draft)
            .update_all(reference_type: :reference_type_question_image)

    question.question_asset_references.where(reference_type: :reference_type_explanation_image_draft)
            .update_all(reference_type: :reference_type_explanation_image)

    question.question_asset_references.where(reference_type: :reference_type_option_image_draft)
            .update_all(reference_type: :reference_type_option_image)

    question.question_asset_references.where(reference_type: :reference_type_passage_draft)
            .update_all(reference_type: :reference_type_passage)
  end

  def check_admin
    if current_user.user_type != :admin
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
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
                                       :question_status, :previous_id, :next_id,
                                       :draft, :created_at, :updated_at)
  end

  def create_question_params
    params.permit(:question, :question_raw, :question_image,
                  :explanation, :explanation_raw, :explanation_image, :position,
                  :options, :answer, :multi_answer, :multiplier, :option_images, :year,
                  :question_image_asset_id, :explanation_image_asset_id, :passage_asset_id,
    )
  end

  def update_question_params
    params.permit(:question, :question_raw, :question_image, :question_image_url,
                  :explanation, :explanation_raw, :explanation_image, :explanation_image_url,
                  :options, :answer, :multi_answer, :multiplier, :option_images, :year,
                  :question_image_asset_id, :explanation_image_asset_id, :passage_asset_id,
    )
  end

  def create_note_params
    params.permit(:note)
  end

  def bulk_set_source_params
    params.permit(:source)
  end

  def bulk_set_year_params
    params.permit(:year)
  end

  def bulk_import_questions_params
    params.permit(:questions_json)
  end

end
