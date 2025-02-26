class AddOptionalToCourseBundlePairs < ActiveRecord::Migration[5.2]
  def change
    add_column :course_bundle_pairs, :optional, :boolean, default: false
  end
end
