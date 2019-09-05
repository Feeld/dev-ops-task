# frozen_string_literal: true

# A message for delivery to the db-daemon
class Message < ApplicationRecord
  after_commit :attempt_delivery, on: :create

  def attempt_delivery
    logger.info("queueing delivery of #{id}")
    DeliverMessageJob.perform_later(self)
  end
end
