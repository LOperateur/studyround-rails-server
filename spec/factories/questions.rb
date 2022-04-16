FactoryBot.define do
  factory :question do
    course { nil }
    question_number { "" }
    question { "MyString" }
    tags { "" }
    question_image_url { "MyString" }
    options { "" }
    answer { "MyString" }
    answer_image_url { "MyString" }
    multi_answer { false }
    multiplier { "" }
    explanation { "MyString" }
    explanation_image_url { "MyString" }
    version { 1 }
    status { "" }
  end
end
