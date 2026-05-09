class OpenaiReportService
  MAX_QUESTIONS_PER_COURSE = 13
  MODEL = "gpt-4o-mini"

  def initialize(result)
    @result = result
  end

  def generate
    session_items = @result.session_items
    return { report: nil, error: "No session items available" } if session_items.blank?

    stats = compute_stats(session_items)
    prompt_items = prepare_prompt_items(session_items)
    course_context = build_course_context

    response = call_openai(stats, prompt_items, course_context)
    response
  rescue Faraday::TimeoutError
    { report: nil, prompt_tokens: nil, completion_tokens: nil, error: "OpenAI request timed out" }
  rescue => e
    { report: nil, prompt_tokens: nil, completion_tokens: nil, error: e.message }
  end

  private

  def compute_stats(session_items)
    total_questions = session_items.size
    correct_count = session_items.count { |item| item["correct"] }
    score_percent = total_questions > 0 ? ((correct_count.to_f / total_questions) * 100).round(1) : 0

    # Per-tag accuracy
    tag_stats = {}
    session_items.each do |item|
      tags = extract_tags(item)
      tags.each do |tag|
        tag_stats[tag] ||= { correct: 0, total: 0 }
        tag_stats[tag][:total] += 1
        tag_stats[tag][:correct] += 1 if item["correct"]
      end
    end

    tag_accuracy = tag_stats.map do |tag, data|
      { tag: tag, correct: data[:correct], total: data[:total], percent: ((data[:correct].to_f / data[:total]) * 100).round(1) }
    end.sort_by { |t| t[:percent] }

    # Time analysis
    time_info = {}
    if @result.respond_to?(:duration) && @result.duration.present?
      time_info[:duration_seconds] = @result.duration
      time_info[:elapsed_seconds] = @result.elapsed_time
      time_info[:time_used_percent] = @result.duration > 0 ? ((@result.elapsed_time.to_f / @result.duration) * 100).round(1) : nil
    end

    {
      total_questions: total_questions,
      correct_count: correct_count,
      score: @result.score,
      total: @result.total,
      score_percent: score_percent,
      session_type: @result.session_type,
      tag_accuracy: tag_accuracy,
      time: time_info,
    }
  end

  def extract_tags(session_item)
    question_data = session_item["question"]
    return [] unless question_data

    tags = question_data["tags"] if question_data.is_a?(Hash)
    return [] unless tags.is_a?(Array)

    tags.compact
  end

  def prepare_prompt_items(session_items)
    courses = build_course_map(session_items)

    if courses.size > 1
      # Multi-course: sample ~13 questions per course, prioritizing incorrect
      sampled = []
      courses.each do |_course_id, items|
        incorrect = items.select { |i| !i["correct"] }
        correct = items.select { |i| i["correct"] }
        sample = (incorrect + correct).first(MAX_QUESTIONS_PER_COURSE)
        sampled.concat(sample)
      end
      sampled
    else
      session_items
    end.map { |item| sanitize_item(item) }
  end

  def build_course_map(session_items)
    grouped = {}
    session_items.each do |item|
      course_id = item.dig("question", "course", "id") || "unknown"
      grouped[course_id] ||= []
      grouped[course_id] << item
    end
    grouped
  end

  def sanitize_item(item)
    clean = {
      "question_text" => item.dig("question", "question"),
      "user_answer" => item["user_answer"],
      "correct_answer" => item["correct_answer"],
      "correct" => item["correct"],
      "multiplier" => item["multiplier"],
      "tags" => extract_tags(item),
      "explanation" => item.dig("question", "explanation"),
    }

    # Include options text only (strip asset data)
    options = item.dig("question", "options")
    if options.is_a?(Array)
      clean["options"] = options.map do |opt|
        if opt.is_a?(Hash)
          opt.slice("option_text", "option_index")
        else
          opt
        end
      end
    end

    clean
  end

  def build_course_context
    if @result.respond_to?(:multi_courses) && @result.multi_courses.present?
      @result.multi_courses.map do |course|
        {
          title: course.title,
          categories: course.respond_to?(:categories) ? course.categories.pluck(:name) : [],
        }
      end
    elsif @result.respond_to?(:course) && @result.course.present?
      [{
        title: @result.course.title,
        categories: @result.course.respond_to?(:categories) ? @result.course.categories.pluck(:name) : [],
      }]
    else
      []
    end
  end

  def call_openai(stats, prompt_items, course_context)
    client = OpenAI::Client.new

    system_prompt = build_system_prompt
    user_prompt = build_user_prompt(stats, prompt_items, course_context)

    response = client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt },
        ],
        temperature: 0.7,
        max_tokens: 2000,
      }
    )

    report_text = response.dig("choices", 0, "message", "content")
    prompt_tokens = response.dig("usage", "prompt_tokens")
    completion_tokens = response.dig("usage", "completion_tokens")

    {
      report: report_text,
      prompt_tokens: prompt_tokens,
      completion_tokens: completion_tokens,
      error: nil,
    }
  end

  def build_system_prompt
    <<~PROMPT
      You are an educational performance analyst for StudyRound, a learning platform. Your role is to analyze quiz and test results and provide helpful, encouraging, and actionable feedback.

      When analyzing results, you should:
      1. Give a brief overall performance summary (2-3 sentences)
      2. Identify strengths — topics/tags where the user performed well
      3. Identify weaknesses — topics/tags where the user needs improvement
      4. Highlight specific questions that were missed and briefly explain why the correct answer is right (without being condescending)
      5. Provide 3-5 actionable study recommendations

      Keep the tone encouraging and constructive. The report should be concise but thorough — aim for 400-600 words.

      IMPORTANT: Format the entire output in standard Markdown. Use proper Markdown headers (##, ###), bullet points (-), bold (**text**), and numbered lists where appropriate. The output must be valid Markdown that can be rendered directly by a Markdown parser.

      IMPORTANT: Answer options are indexed numerically (1-26) in the data, but these map to letters A-Z. Always refer to options by their letter label, not their number. For example: 1=A, 2=B, 3=C, 4=D, ..., 26=Z. So if the correct answer is [2], write "B" in the report, not "2".
    PROMPT
  end

  def build_user_prompt(stats, prompt_items, course_context)
    data = {
      session_type: stats[:session_type],
      courses: course_context,
      overall_performance: {
        score: "#{stats[:score]}/#{stats[:total]}",
        percent: "#{stats[:score_percent]}%",
        questions_answered: stats[:total_questions],
        correct: stats[:correct_count],
        incorrect: stats[:total_questions] - stats[:correct_count],
      },
      per_topic_accuracy: stats[:tag_accuracy],
      time_analysis: stats[:time],
      questions: prompt_items,
    }

    "Please analyze the following #{stats[:session_type]} results and generate a performance report:\n\n#{data.to_json}"
  end
end
