FactoryBot.define do
  factory :performance_report do
    result
    user { result.user }
    status { 2 }
    report_content { "Test report content" }
    prompt_tokens { 500 }
    completion_tokens { 300 }
    error_message { nil }
  end
end
