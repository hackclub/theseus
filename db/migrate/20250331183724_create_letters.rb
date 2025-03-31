class CreateLetters < ActiveRecord::Migration[8.0]
  def change
    create_table :letters do |t|
      t.integer :processing_category
      t.text :body
      t.string :aasm_state
      t.references :mailer_id, null: false, foreign_key: true
      t.decimal :postage
      t.integer :imb_serial_number
      t.references :address, null: false, foreign_key: true
      t.integer :imb_rollover_count
      t.integer :imb_stid
      t.string :recipient_email
      t.decimal :weight
      t.decimal :width
      t.decimal :height
      t.boolean :non_machinable
      t.string :aasm_state

      t.timestamps
    end
  end
end
