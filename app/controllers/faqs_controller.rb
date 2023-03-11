class FaqsController < ApplicationController
  skip_before_action :authorize!, only: [:index]

  def index
    faqs = paginate(faq_list, params)
    render json: {
      data: faqs
    }.merge(paginated_meta(faqs))
  end

  private

  def faq_list
    [
      {
        question: "What is the difference between a course and a test?",
        answer: "A Course is the basic way we consume content on U-Learn using three modes - Quiz, Practice and Study. A Test is a way to strictly test your knowledge on any topic as set out by the creator of the test."
      },
      {
        question: "What do the modes - Quiz, Practice and Study mean?",
        answer: "Quiz, Practice and Study refer to the way you consume content on U-Learn. Quiz is a quick fire mode where you are tested on your knowledge of a topic. Practice is a mode where you can practice the topic as if it were a test, and Study is a mode where you can read about the topic."
      },
    # Todo: Add more FAQs
    ]
  end
end
