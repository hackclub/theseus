class CreatePublicImpersonations < ActiveRecord::Migration[8.0]
  def change
    create_table :public_impersonations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :justification

      t.timestamps
    end
  end
end
