class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages, id: :uuid do |t|
      t.text :payload
      t.boolean :failing
      t.boolean :delivered
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
