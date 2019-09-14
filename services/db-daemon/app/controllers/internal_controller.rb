# frozen_string_literal: true

class InternalController < ApplicationController
  def metrics
    @metrics = build_metrics
    render '/internal/metrics.txt.erb',
           layout: false,
           content_type: 'text/plain'
  end

  def healthz
    @metrics = build_metrics
    render '/internal/healthz.json.jbuilder',
           layout: false,
           content_type: 'application/json'
  end

  def root
    render json: { "status": "ok" }
  end

  private

  def build_metrics
    OpenStruct.new(
      db_rtt: db_rtt,
      received_messages: Message.count,
      time: Time.now.to_i
    )
  end

  def db_rtt
    Benchmark.realtime do
      ActiveRecord::Base.connection.execute('SELECT VERSION()')
    end
  end

end
