unless Rails.env.production?
  # Create Questions for the Web 3.0 course
  web3_course = Course.find_by(title: "Web 3.0")
  Question.create(
    [
      {
        course: web3_course,
        question_number: 1,
        question: "What is Web 3.0?",
        question_image_url: "https://play-lh.googleusercontent.com/rNgpb_TlfsoaKOqFwf8CFDpVjWymv8Zdh8a3EEz8UjEEhND-oWWpIxbeQSoN7akz-nE",
        options: [
          {
            id: 1,
            text: "A game"
          },
          {
            id: 2,
            text: "Life"
          },
          {
            id: 3,
            text: "New Blockchain technology"
          },
          {
            id: 4,
            text: "Another game"
          }
        ],
        answer: 3,
        answer_image_url: "https://play-lh.googleusercontent.com/rNgpb_TlfsoaKOqFwf8CFDpVjWymv8Zdh8a3EEz8UjEEhND-oWWpIxbeQSoN7akz-nE",
        explanation: "Who really knows?",
        explanation_image_url: "https://play-lh.googleusercontent.com/rNgpb_TlfsoaKOqFwf8CFDpVjWymv8Zdh8a3EEz8UjEEhND-oWWpIxbeQSoN7akz-nE",
        status: :status_published
      }
    ]
  )
end
