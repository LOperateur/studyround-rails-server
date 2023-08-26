class Category < ApplicationRecord

  validates :name, presence: true, uniqueness: true

  has_many :interests, dependent: :destroy
  has_many :users, through: :interests
  has_many :categorizations, dependent: :destroy
  has_many :courses, through: :categorizations

  scope :published_active_course_categories, -> { joins(:courses).where(courses: { publish_status: :publish_status_published, course_status: :course_status_active, private: false }) }

  # Here are our current category definitions across levels:
  # More categories can be added as needed...
  # {
  #   "Occupation": "Student" | "Professional" | "Default"
  #   "Student order": "5, 3, 2, 1, 4"
  #   "Professional order": "4, 1, 5, 3, 2"
  #   "Default order": "1, 4, 5, 2, 3"
  #
  #   "category_levels": [
  #       "1-faculty": ["General Knowledge","Engineering","Medical Sciences","Agriculture","Sciences","Legal","Arts & Humanities","Business","Social Sciences","Education","Environmental Sciences"],
  #       "2-examinations": ["JAMB","Post UTME","WAEC"],
  #       "3-institutions": ["UNIBEN","DELSU"],
  #       "4-sectors": ["Finance","Technology","Fashion","Health & Wellness","International","Government","Entertainment","History","Sports","Religious","IQ"],
  #       "5-institution-type": ["University","College","Polytechnic","Secondary","Primary","Adult School"]
  #   ]
  # }

  # Used to serialize the category model for categorised courses on the go without having to render
  def serialized_categorised_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: CategorisedCourseSerializer).as_json
  end
end
