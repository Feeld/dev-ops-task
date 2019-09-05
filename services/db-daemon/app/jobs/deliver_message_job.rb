# frozen_string_literal: true

class DeliverMessageJob < ApplicationJob
  retry_on MessageDeliveryError

  queue_as :default

  def perform(msg)
    delivery_status = send_to_db(msg)
    if delivery_status.ok
      msg.delivered_at = Time.now
      msg.delivered = true
      msg.failing = false
      LogEntry.create(
        message_id: msg.id,
        failing: false,
        details: 'delivery successful'
      )
      msg.save!
    else
      msg.delivered = false
      msg.failing = true
      LogEntry.create(
        message_id: msg.id,
        failing: true,
        details: "delivery failed: [#{delivery_status.code}] #{delivery_status.reason}"
      ).save!
      msg.save!
      raise MessageDeliveryError
    end
  end

  def send_to_db(msg)
    resp = Faraday.new(url: Rails.configuration.delivery_endpoint).post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = msg.to_json
    end
    if resp.status == 200
      OpenStruct.new(
        ok: true,
        status: resp.status
      )
    else
      OpenStruct.new(
        ok: false,
        status: resp.status,
        reason: resp.reason_phrase
      )
    end
  rescue Faraday::Error => e
    OpenStruct.new(
      ok: false,
      status: 'Faraday',
      reason: e.to_s
    )
  end
end
