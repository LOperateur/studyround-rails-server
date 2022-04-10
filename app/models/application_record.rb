class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :created_before, ->(time) { where('created_at < ?', time) }
  scope :updated_before, ->(time) { where('updated_at < ?', time) }
  scope :created_after, ->(time) { where('created_at > ?', time) }
  scope :updated_after, ->(time) { where('updated_at > ?', time) }
end
