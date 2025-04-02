class CreateReturnAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :return_addresses do |t|
      t.string :name
      t.string :line_1
      t.string :line_2
      t.string :city
      t.string :state
      t.string :postal_code
      t.integer :country
      t.boolean :shared
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
