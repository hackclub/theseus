class AddEmailToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :email, :string
  end
end
