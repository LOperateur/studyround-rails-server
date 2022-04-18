# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Category.count == 0
  Category.create(
    [
      { name: "General Knowledge", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Engineering", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Agriculture", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Earth", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Sciences", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Legal", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Arts & Humanities", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Finance", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Social Sciences", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Technology", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "Sports", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
      { name: "International", level: 1, image_url: "categories/AfricanMaskIcon.svg" },
    ]
  )
end

unless Rails.env.production?
  # Any user
  user = User.first || User.create(username: "mofe", email: "mofe@gmail.com", password: "12345678", password_confirmation: "12345678")

  # All courses to be pre-seeded
  if Course.count == 0
    Course.create(
      [
        {
          creator: user,
          title: "A Brief History of Time",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "By Stephen Hawkings, a simple course about time.",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "All about Archeology",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "A deep dive into what lies beneath the earth's surface",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Mathematics for Dummies",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "Some basic knowledge about some basic maths.",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Mathematics for Dummies 2",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "Some more basic knowledge about some basic maths.",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Countries and Capitals",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "How much do you know about your countries?",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Fun with Flags",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "Ever heard about Vexillology?",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Movies of Nigeria",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "A journey through Nigeria's timeless classics",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Movies of Africa",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "A journey through Africa's timeless classics",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "History of Football",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "From the World Cup to the Premier league and more! How much do you know about The Beautiful Game?",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Landlord and Tenant",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "A brewing battle between one of the oldest known business relationships",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          creator: user,
          title: "Nigerian Banking",
          sale_status: :sale_status_free,
          price: 0.00,
          currency: "NGN",
          private: false,
          test: false,
          about: "Information on Nigeria's banks and how they operate",
          version: 1,
          course_status: :course_status_active,
          publish_status: :publish_status_published,
          rating: 4.6,
          completed: false,
        },
        {
          "creator": user,
          "title": "Web 3.0",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": 'An In-depth analysis of Cryptocurrency, NFT\'s and Smart Contracts',
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.2,
          "completed": false
        },
        {
          "creator": user,
          "title": "Graphic Design",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A course entailing the methods of engraving, etching, lithography, photography, serigraphy, and woodwork",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.7,
          "completed": false
        },
        {
          "creator": user,
          "title": "Sub-Saharan Irrigation",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A questionnaire on sub-saharan irrigation practices",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.6,
          "completed": false
        },
        {
          "creator": user,
          "title": "A History of Amateur Wrestling",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "An account on the advent of amateur wrestling",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.9,
          "completed": false
        },
        {

          "creator": user,
          "title": "Semi-Conductors",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "An analysis of semiconductors and their conductivity at low and high temperatures ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.1,
          "completed": false
        },
        {
          "creator": user,
          "title": "Electronic configuration",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "How to calculate the electronic configuration of an element",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.1,
          "completed": false
        },
        {
          "creator": user,
          "title": "Stoicism",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "An analysis of semiconductors and their conductivity at low and high temperatures",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.3,
          "completed": false
        },
        {
          "creator": user,
          "title": "Property Law",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A rundown of property law in Nigeria ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "Content Writing",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A questionnaire on content creation as it relates to written media ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "Weaving",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "Interlacing yarn and filling threads intricately ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "Japanese Cuisine",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A course on homemade and professional japanese cooking",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.1,
          "completed": false
        },
        {
          "creator": user,
          "title": '90\'s Animation Style',
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "Analysing 90s animation and how it influenced animation that came after",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.4,
          "completed": false
        },
        {
          "creator": user,
          "title": "NATO",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A history of NATO and how it's influenced international politics",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.2,
          "completed": false
        },
        {
          "creator": user,
          "title": "The Silmarillion",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "A questionnaire about J.R.R Tolkien's epic novel",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 2.2,
          "completed": false
        },
        {
          "creator": user,
          "title": "Raspberry Pi",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "All the applications that the mini computer can be used for",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 3.5,
          "completed": false
        },
        {
          "creator": user,
          "title": "Shonen Manga",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "An examination of the common features of shonen manga ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 4.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "Anthropology",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "The study of human beings and their ancestor through time and space ",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 5.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "Trade and Commerce",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "Humanity and our means of exchange",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 5.0,
          "completed": false
        },
        {
          "creator": user,
          "title": "The Great Depression",
          "sale_status": :sale_status_free,
          "price": 0.00,
          "currency": "NGN",
          "private": false,
          "test": false,
          "about": "Learn about one of the most recent Economic disasters to hit the globe, and also how to prevent another",
          "version": 1,
          "course_status": :course_status_active,
          "publish_status": :publish_status_published,
          "rating": 5.0,
          "completed": false
        }
      ]
    )
  end

  # Course categorization
  if Categorization.count == 0
    Categorization.create(
      [
        {
          course: Course.find_by(title: "A Brief History of Time"),
          category: Category.find_by(name: "Sciences")
        },
        {
          course: Course.find_by(title: "A Brief History of Time"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "All about Archeology"),
          category: Category.find_by(name: "Sciences")
        },
        {
          course: Course.find_by(title: "All about Archeology"),
          category: Category.find_by(name: "Earth")
        },
        {
          course: Course.find_by(title: "Mathematics for Dummies"),
          category: Category.find_by(name: "Sciences")
        },
        {
          course: Course.find_by(title: "Mathematics for Dummies"),
          category: Category.find_by(name: "Engineering")
        },
        {
          course: Course.find_by(title: "Countries and Capitals"),
          category: Category.find_by(name: "Earth")
        },
        {
          course: Course.find_by(title: "Countries and Capitals"),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: "Countries and Capitals"),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: "Fun with Flags"),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: "Fun with Flags"),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: "Movies of Nigeria"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Movies of Nigeria"),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: "Movies of Nigeria"),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: "Movies of Africa"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Movies of Africa"),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: "Movies of Africa"),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: "History of Football"),
          category: Category.find_by(name: "Sports")
        },
        {
          course: Course.find_by(title: "History of Football"),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: "Landlord and Tenant"),
          category: Category.find_by(name: "Legal")
        },
        {
          course: Course.find_by(title: "Landlord and Tenant"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Web 3.0"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "Web 3.0"),
          category: Category.find_by(name: "Finance")
        },
        {
          course: Course.find_by(title: "Web 3.0"),
          category: Category.find_by(name: "Engineering")
        },
        {
          course: Course.find_by(title: "Graphic Design"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "Graphic Design"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          category: Category.find_by(name: "Agriculture")
        },
        {
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          category: Category.find_by(name: "Earth")
        },
        {
          course: Course.find_by(title: "A History of Amateur Wrestling"),
          category: Category.find_by(name: "Sports")
        },
        {
          course: Course.find_by(title: "A History of Amateur Wrestling"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Semi-Conductors"),
          category: Category.find_by(name: "Engineering")
        },
        {
          course: Course.find_by(title: "Semi-Conductors"),
          category: Category.find_by(name: "Sciences")
        },
        {
          course: Course.find_by(title: "Semi-Conductors"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "Electronic configuration"),
          category: Category.find_by(name: "Sciences")
        },
        {
          course: Course.find_by(title: "Electronic configuration"),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: "Stoicism"),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: "Stoicism"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Property Law"),
          category: Category.find_by(name: "Legal")
        },
        {
          course: Course.find_by(title: "Property Law"),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: "Content Writing"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Content Writing"),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: "Weaving"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Weaving"),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: "Japanese Cuisine"),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: "Japanese Cuisine"),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: '90\'s Animation Style'),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: '90\'s Animation Style'),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: 'NATO'),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: 'NATO'),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: 'The Silmarillion'),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: 'Raspberry Pi'),
          category: Category.find_by(name: "Engineering")
        },
        {
          course: Course.find_by(title: 'Raspberry Pi'),
          category: Category.find_by(name: "Technology")
        },
        {
          course: Course.find_by(title: 'Shonen Manga'),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: 'Anthropology'),
          category: Category.find_by(name: "Arts & Humanities")
        },
        {
          course: Course.find_by(title: 'Anthropology'),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: 'Nigerian Banking'),
          category: Category.find_by(name: "Finance")
        },
        {
          course: Course.find_by(title: 'Nigerian Banking'),
          category: Category.find_by(name: "General Knowledge")
        },
        {
          course: Course.find_by(title: 'Trade and Commerce'),
          category: Category.find_by(name: "Finance")
        },
        {
          course: Course.find_by(title: 'Trade and Commerce'),
          category: Category.find_by(name: "International")
        },
        {
          course: Course.find_by(title: 'Trade and Commerce'),
          category: Category.find_by(name: "Legal")
        },
        {
          course: Course.find_by(title: 'Trade and Commerce'),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: 'The Great Depression'),
          category: Category.find_by(name: "Finance")
        },
        {
          course: Course.find_by(title: 'The Great Depression'),
          category: Category.find_by(name: "Social Sciences")
        },
        {
          course: Course.find_by(title: 'The Great Depression'),
          category: Category.find_by(name: "International")
        }
      ]
    )
  end

  # Interests for our User
  if Interest.count == 0
    Interest.create(
      [
        {
          user: user,
          category: Category.find_by(name: "Sciences"),
          affinity: 2
        },
        {
          user: user,
          category: Category.find_by(name: "Engineering"),
          affinity: 1
        },
        {
          user: user,
          category: Category.find_by(name: "Finance"),
          affinity: 0
        }
      ]
    )
  end

  # Create Results
  if Result.count == 0
    Result.create(
      [
        {
          user: user,
          course: Course.find_by(title: "A Brief History of Time"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "A Brief History of Time"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "All about Archeology"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "All about Archeology"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Mathematics for Dummies"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Mathematics for Dummies"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Countries and Capitals"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Countries and Capitals"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Countries and Capitals"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Fun with Flags"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Fun with Flags"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Nigeria"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Nigeria"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Nigeria"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Africa"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Africa"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Movies of Africa"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "History of Football"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "History of Football"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Landlord and Tenant"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Landlord and Tenant"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Web 3.0"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Web 3.0"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Web 3.0"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Web 3.0"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Graphic Design"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "Sub-Saharan Irrigation"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        },
        {
          user: user,
          course: Course.find_by(title: "A History of Amateur Wrestling"),
          score: rand(51),
          total: rand(51..100),
          duration: 3600,
          mode: :mode_practice
        }
      ]
    )
  end
end

# Time.now.strftime("%Y%m%d%H%M%S")

Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].sort.each do |seed|
  load seed
end
