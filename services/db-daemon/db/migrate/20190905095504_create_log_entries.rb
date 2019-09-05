# frozen_string_literal: true

class CreateLogEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :log_entries, id: :uuid do |t|
      t.text :details
      t.boolean :failing
      t.uuid :message_id

      t.timestamps
    end
  end
end
