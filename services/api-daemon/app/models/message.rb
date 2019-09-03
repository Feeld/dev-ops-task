# frozen_string_literal: true

class Message < ApplicationRecord
  def attempt_delivery
    logger.debug("attempting delivery of #{to_json}")
    if send_to_db
      self.delivered_at = Time.now
      self.delivered = true
      self.error = false
      LogEntry.create(
        message_id: id,
        error: false,
        message: 'delivery successful'
      )
    else
      self.delivered = false
      self.error = true
      LogEntry.create(
        message_id: id,
        error: true,
        message: 'delivery failed: unknown error'
      )
    end
    save!
    self
  end

  def send_to_db
    true
  end
end