# frozen_string_literal: true

json.array! @log_entries, partial: 'log_entries/log_entry', as: :log_entry
