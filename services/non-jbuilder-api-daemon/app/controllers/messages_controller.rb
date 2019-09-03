# frozen_string_literal: true

class MessagesController < ApplicationController
  def create
    payload = params.require(:payload)
    m = Message.create(payload: payload).attempt_delivery
    Message.where(delivered: false).collect(&:attempt_delivery)
    render json: m
  rescue ActionController::ParameterMissing => e
    render json: { error: e.to_s }
  end
end
