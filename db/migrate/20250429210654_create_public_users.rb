class CreatePublicUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :public_users do |t|
      t.string :email

      t.timestamps
    end
  end
end
