class CategorisedCourseSerializer < ActiveModel::Serializer
  type :category
  attributes :id, :name

  has_many :courses do
    # Todo: Use a formula between ratings and rating count before ordering
    # This will prevent 5-star courses with just 1 review from topping the list
    # See potential solution here: https://stackoverflow.com/a/1411268/3993638 and https://en.m.wikipedia.org/wiki/IMDb#Rankings
    object.courses.published_active_courses.limit(12).order("rating desc nulls last")
  end
end
