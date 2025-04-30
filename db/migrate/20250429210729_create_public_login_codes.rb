class CreatePublicLoginCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :public_login_codes do |t|
      t.string :token
      t.datetime :expires_at
      t.timestamps
    end
  end
end
