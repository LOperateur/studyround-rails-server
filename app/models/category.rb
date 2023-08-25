class Category < ApplicationRecord

  validates :name, presence: true, uniqueness: true

  has_many :interests, dependent: :destroy
  has_many :users, through: :interests
  has_many :categorizations, dependent: :destroy
  has_many :courses, through: :categorizations

  # Here are our current category definitions across levels:
  # More categories can be added as needed...
  # {
  #   "category_levels": [
  #       "1-faculty": ["General Knowledge","Engineering","Agriculture","Earth","Sciences","Legal",
  #                     "Arts & Humanities","Finance","Social Sciences","Technology","International","IQ"],
  #       "2-examinations": ["JAMB","P-UTME","WAEC"],
  #       "3-institutions": ["UNIBEN","DELSU"],
  #       "4-sectors": ["Banking","Tech","Fashion"],
  #       "5-institution-type": ["University","College","Polytechnic","Secondary","Primary","Adult School"]
  #   ]
  # }

  # Used to serialize the category model for categorised courses on the go without having to render
  def serialized_categorised_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: CategorisedCourseSerializer).as_json
  end
end
