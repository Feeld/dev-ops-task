# frozen_string_literal: true

class InternalController < ApplicationController
  def metrics
    @metrics = build_metrics
    render '/internal/metrics.txt.erb',
           layout: false,
           content_type: 'application/openmetrics-text'
  end

  def healthz
    @metrics = build_metrics
    render '/internal/healthz.json.jbuilder',
           layout: false,
           content_type: 'application/json'
  end

  private

  def build_metrics
    OpenStruct.new(
      db_rtt: db_rtt,
      redis_rtt: redis_rtt,
      processed_deliveries: Resque.data_store.stat(:processed),
      failed_deliveries: Resque.data_store.stat(:failed),
      time: Time.now.to_i
    )
  end

  def db_rtt
    Benchmark.realtime do
      ActiveRecord::Base.connection.execute('SELECT VERSION()')
    end
  end

  def redis_rtt
    Benchmark.realtime do
      Redis.new(
        url: ENV['REDIS_URL'],
        thread_safe: true
      )
    end
  end

end
