class PerformanceReportSerializer < ActiveModel::Serializer
  attributes :id, :result_id, :report_content, :created_at, :score, :total, :percent, :courses

  def score
    object.result.score
  end

  def total
    object.result.total
  end

  def percent
    ((object.result.score.to_f / object.result.total.to_f) * 100).round(2)
  end

  def courses
    result = object.result
    if result.course.present?
      [result.course.serialized_mini_course]
    else
      result.multi_courses.map(&:serialized_mini_course)
    end
  end
end
