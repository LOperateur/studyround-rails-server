unless Rails.env.production?
  user = User.first

  if CourseReview.count == 0
    CourseReview.create(
      [
        {
          course: Course.find_by(title: "A Brief History of Time"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "All about Archeology"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "Mathematics for Dummies"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "Countries and Capitals"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "Landlord and Tenant"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "Web 3.0"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: "Fun with Flags"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          user: user,
          rating: 4.0,
          review: "I like it"
        },
        {
          course: Course.find_by(title: "A History of Amateur Wrestling"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: "Semi-Conductors"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: "Property Law"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: "Movies of Africa"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: "Weaving"),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: '90\'s Animation Style'),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: 'NATO'),
          user: user,
          rating: 5.0,
          review: "I love it"
        },
        {
          course: Course.find_by(title: 'The Silmarillion'),
          user: user,
          rating: 3.0,
          review: "I am indifferent about it"
        },
        {
          course: Course.find_by(title: 'Raspberry Pi'),
          user: user,
          rating: 3.0,
          review: "I am indifferent about it"
        },
        {
          course: Course.find_by(title: 'Anthropology'),
          user: user,
          rating: 3.0,
          review: "I am indifferent about it"
        },
        {
          course: Course.find_by(title: 'Nigerian Banking'),
          user: user,
          rating: 3.0,
          review: "I am indifferent about it"
        },
        {
          course: Course.find_by(title: 'The Great Depression'),
          user: user,
          rating: 3.0,
          review: "I am indifferent about it"
        }
      ]
    )
  end
end
