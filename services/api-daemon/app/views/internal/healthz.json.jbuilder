# frozen_string_literal: true

json.web 'ok'
json.db_rtt_ms number_with_precision(@metrics.db_rtt * 1000, precision: 3).to_f
json.redis_rtt_ms number_with_precision(@metrics.redis_rtt * 1000, precision: 3).to_f
json.failed_deliveries @metrics.failed_deliveries.to_i
json.processed_deliveries @metrics.processed_deliveries.to_i
