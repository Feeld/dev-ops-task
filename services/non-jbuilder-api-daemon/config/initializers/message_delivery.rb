# frozen_string_literal: true

endpoint = ENV['DELIVERY_ENDPOINT'] || 'http://127.0.0.1:3000/messages'
Rails.configuration.delivery_endpoint = URI.parse(endpoint)


