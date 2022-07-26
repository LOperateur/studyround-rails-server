class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :created_before, ->(time, table_prefix="") { where("#{table_prefix}created_at < ?", time) }
  scope :updated_before, ->(time, table_prefix="") { where("#{table_prefix}updated_at < ?", time) }
  scope :created_after, ->(time, table_prefix="") { where("#{table_prefix}created_at > ?", time) }
  scope :updated_after, ->(time, table_prefix="") { where("#{table_prefix}updated_at > ?", time) }

  scope :recent, -> { order(created_at: :desc) }
end
