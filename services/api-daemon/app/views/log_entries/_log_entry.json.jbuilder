json.extract! log_entry, :id, :details, :failing, :message_id, :created_at, :updated_at
json.url log_entry_url(log_entry, format: :json)
