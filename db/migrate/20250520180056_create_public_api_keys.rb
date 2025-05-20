class CreatePublicAPIKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :public_api_keys do |t|
      t.references :public_user, null: false, foreign_key: true
      t.string :token
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
