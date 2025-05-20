class AddNameToPublicAPIKey < ActiveRecord::Migration[8.0]
  def change
    add_column :public_api_keys, :name, :string
  end
end
