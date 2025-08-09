class TriviaSet < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :sessions, dependent: :nullify
  has_many :results, dependent: :nullify

  enum trivia_status: {
    active: 1,
    suspended: 2,
    expired: 3,
    closed: 4,
    deleted: 5,
  }, _prefix: true

  scope :non_deleted_trivia, -> { where.not(trivia_status: :deleted) }

  def send_trivia_status_emails
    expiration = self.expiration
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (self.rules['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    if is_closeable
      TriviaMailer.with(
        email: self.creator.email,
        title: self.title,
        trivia_id: self.id,
      ).close_trivia_email.deliver_later
    else
      time_left = closing_time - Time.now

      TriviaMailer.with(
        email: self.creator.email,
        title: self.title,
        trivia_id: self.id,
        closing_time: "#{closing_time.to_formatted_s(:long_ordinal)} GMT",
      ).expired_trivia_email.deliver_later

      TriviaMailer.with(
        email: self.creator.email,
        title: self.title,
        trivia_id: self.id,
      ).close_trivia_email.deliver_later(wait: (time_left).seconds)
    end
  end
end
