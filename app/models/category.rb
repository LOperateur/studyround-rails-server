class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category'

  # Also has categories in sub levels
end
