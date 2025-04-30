class AddUserToPublicLoginCodes < ActiveRecord::Migration[8.0]
  def change
    add_reference :public_login_codes, :user, null: false, foreign_key: { to_table: :public_users}
  end
end
