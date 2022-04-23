class RenameCourseReviewToReview < ActiveRecord::Migration[5.2]
  def change
    rename_table :course_reviews, :reviews
  end
end
