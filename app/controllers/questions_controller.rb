class QuestionsController < ApplicationController
  include CourseHelper
  include SessionHelper
  include TestHelper

  skip_before_action :authorize!, only: [:preview]
  before_action :load_creators_course, except: [:index, :explanation, :preview]
  before_action :load_question, only: [:show, :update, :publish, :destroy, :add_note, :remove_note, :resolve_notes, :hard_update]
  before_action :published_test_check, only: [:create, :update, :publish, :destroy]

  wrap_parameters format: []

  def explanation
    # Todo: Rewrite this starting from the context of a course
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

  def preview
    course = Course.find(params[:course_id])

    is_course_owned = is_course_owner?(course, current_user)
    is_course_accessible = course.publish_status_published? && course.course_status_active?
    is_course_free = course.sale_status_free? || course.sale_status_explanations?

    if current_user
      is_course_purchased = current_user.has_purchased_item(course)

      if is_course_owned
        question = course.questions.find(params[:question_id])
      elsif is_course_accessible && (is_course_free || is_course_purchased)
        question = course.questions.published_active_questions.find(params[:question_id])
      else
        raise Errors::ForbiddenError.new(message: "You don't have the authority to preview this question")
      end
    else
      if is_course_accessible && is_course_free
        question = course.questions.published_active_questions.find(params[:question_id])
      else
        raise Errors::ForbiddenError.new(message: "Please sign in to preview this particular question")
      end
    end

    render json: question, root: :data, serializer: QuestionAnswerSerializer, status: :ok
  end

  # From a Creator's point of view

  def questions
    # Filter by year if present
    year = params[:year].presence

    # Custom pagination for find_by_sql
    total_questions = @course.questions.non_deleted_questions.filtered_by_draft_year(year).count
    limit, offset, paginated_metadata = custom_paginate(total_questions, params)

    # Recursive CTE to get questions in order
    # This corresponds to a non-deleted questions query
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
    WHERE NOT question_status = 3 
    AND (? IS NULL OR (draft->>'year' = ? OR (draft IS NULL AND year = ?))) -- Filter by year (draft first, then published)
    LIMIT ? OFFSET ?
    SQL

    questions = Question.find_by_sql([cte_query, @course.id, year, year, year, limit, offset])

    render json: { data: questions.map do |question|
      question.serialized_creator_question_list_item
    end
    }.merge(paginated_metadata)

  end

  def show
    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def create
    case @course.creator.creator_status.to_sym
    when :creator_status_limited
      if @course.questions.non_deleted_questions.count >= 100
        raise Errors::ForbiddenError.new(message: "The owner of this course has limited creator status. You can only create 100 questions")
      end
    when :creator_status_full
      if @course.questions.non_deleted_questions.count >= 2000
        raise Errors::ForbiddenError.new(message: "You have reached the maximum number of questions for this course")
      end
    else
      # Do nothing
    end

    draft = create_draft(create_question_params)
    question = @course.questions.build
    question.draft = draft

    # Identify the original creator
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

    Question.transaction do
      # Reference Assets and update the question
      build_asset_references(@question)
      @question.save!
    end

    render json: @question, root: :data, serializer: CreatorQuestionSerializer
  end

  def hard_update
    # This method is used to update a question without creating a new draft
    # It is used when the question is being edited in a test session
    if @question.version == 0
      raise Errors::BaseError.new(message: "This question has not yet been published", status: 400)
    end

    @question.update!(update_question_params)
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

    # Set all the years for the questions in the course to year

    # If the question has been published, update the year column
    @course.questions.non_deleted_questions.where.not(version: 0).update_all(year: year)

    # If the question has a draft, then set the year to the draft json too
    year_value = year.nil? ? "null" : %("#{year}") # Ensure JSON null value or a year string value (not integer)
    update_draft_year_sql = "draft = jsonb_set(draft, '{year}', ?)"
    @course.questions.non_deleted_questions.where.not(draft: nil).update_all([update_draft_year_sql, year_value])

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

    # Todo: Add roles and permissions check for update-own, destroy-own

    # Mapping roles to their allowed methods
    roles_and_methods = {
      :admin => [:questions, :show, :create, :update, :publish, :hard_update,
                 :destroy, :add_note, :remove_note, :resolve_notes, :publish_questions,
                 :bulk_set_source, :bulk_set_year, :bulk_import_questions_json],

      :creator => [:questions, :show, :create, :update, :publish,
                 :destroy, :add_note, :remove_note, :resolve_notes, :publish_questions],

      :co_creator => [:questions, :show, :create, :update, :publish,
                           :destroy, :add_note, :remove_note, :publish_questions],

      :editor => [:questions, :show, :create, :update,
                       :destroy, :add_note, :remove_note],
    }

    # Check the user level/role and permissions
    if current_user.user_type == :admin
      if !roles_and_methods[:admin].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    elsif @course.creator == current_user
      if !roles_and_methods[:creator].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    elsif CourseCollaborator.where(user: current_user, course: @course).exists?
      role = CourseCollaborator.where(user: current_user, course: @course).take.role.to_sym
      if !roles_and_methods[role].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    else
      raise Errors::ForbiddenError.new(message: "You don't have the authority to manage the questions in this course.")
    end
  end

  def load_question
    begin
      @question = @course.questions.non_deleted_questions.find(params[:id])
    rescue
      raise Errors::NotFoundError.new(message: "Cannot find this question in the course")
    end
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
      data: result
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
        :position, :question_image_asset_id, :explanation_image_asset_id, :passage_asset_id,
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
    params.permit(:question, :question_raw, :explanation, :explanation_raw, :position,
                  :options, :answer, :multi_answer, :multiplier, :year,
                  :question_image_asset_id, :explanation_image_asset_id, :passage_asset_id,
    )
  end

  def update_question_params
    params.permit(:question, :question_raw, :explanation, :explanation_raw,
                  :options, :answer, :multi_answer, :multiplier, :year,
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
