unless Rails.env.production?
  # Create Questions for the Web 3.0 course
  u_learn_logo_url = "https://play-lh.googleusercontent.com/rNgpb_TlfsoaKOqFwf8CFDpVjWymv8Zdh8a3EEz8UjEEhND-oWWpIxbeQSoN7akz-nE"
  web3_course = Course.find_by(title: "Web 3.0")
  Question.create(
    [
      {
        course: web3_course,
        question_number: 1,
        question: "What is Web 3.0?",
        question_image_url: u_learn_logo_url,
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
        answer_image_url: u_learn_logo_url,
        explanation: "Who really knows?",
        explanation_image_url: u_learn_logo_url,
        publish_status: :publish_status_published
      },
      {
        course: web3_course,
        question_number: 2,
        question: "What is the Blockchain",
        options: [
          {
            id: 1,
            text: "New tech meant to enhance data movement"
          },
          {
            id: 2,
            text: "Bitcoin"
          },
          {
            id: 3,
            text: "Crypto"
          },
          {
            id: 4,
            text: "Another crypto"
          }
        ],
        answer: 1,
        explanation: "Who really knows?",
        publish_status: :publish_status_published
      },
    ]
  )
end
