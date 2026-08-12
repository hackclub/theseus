class CreateWarehouseSKURequests < ActiveRecord::Migration[8.0]
  def change
    create_table :warehouse_sku_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :warehouse_sku, foreign_key: { to_table: :warehouse_skus }

      t.string :name, null: false
      t.text :description
      t.string :category
      t.decimal :unit_cost, precision: 10, scale: 2
      t.string :country_of_origin
      t.string :hs_code
      t.text :customs_description
      t.string :program
      t.date :expected_arrival
      t.integer :expected_quantity
      t.string :suggested_sku_code
      t.string :assigned_sku_code

      t.string :aasm_state, null: false, default: "draft"
      t.text :rejection_reason
      t.datetime :submitted_at
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :warehouse_sku_requests, :aasm_state
  end
end
