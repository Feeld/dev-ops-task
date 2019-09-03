# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.text :payload
      t.boolean :error
      t.boolean :delivered
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
