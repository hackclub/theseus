class RenameApkTokenField < ActiveRecord::Migration[8.0]
  def change
    rename_column :public_api_keys, :token, :token_ciphertext
    add_column :public_api_keys, :token_bidx, :string
    add_index :public_api_keys, :token_bidx, unique: true
  end
end
