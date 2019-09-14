# frozen_string_literal: true

json.web 'ok'
json.db_rtt_ms number_with_precision(@metrics.db_rtt * 1000, precision: 3).to_f
json.received_messages @metrics.received_messages.to_i
