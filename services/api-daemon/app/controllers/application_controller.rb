# frozen_string_literal: true

class ApplicationController < ActionController::API
  # probably only needed for full Rails
  # protect_from_forgery unless: -> { request.format.json? }
end
