# frozen_string_literal: true

class CreateLogEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :log_entries do |t|
      t.integer :message_id
      t.boolean :error
      t.text :message

      t.timestamps
    end
  end
end
