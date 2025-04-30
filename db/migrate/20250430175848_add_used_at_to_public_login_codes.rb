class AddUsedAtToPublicLoginCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :public_login_codes, :used_at, :datetime
  end
end
