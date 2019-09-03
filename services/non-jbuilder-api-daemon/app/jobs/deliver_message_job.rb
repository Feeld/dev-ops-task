# frozen_string_literal: true

class DeliverMessageJob < ApplicationJob
  queue_as :default

  def perform(msg)
    Faraday.new(url: Rails.configuration.delivery_endpoint).post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = msg.to_json
    end
  end
end

