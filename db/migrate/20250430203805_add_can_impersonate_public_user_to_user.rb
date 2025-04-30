class AddCanImpersonatePublicUserToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :can_impersonate_public, :boolean
  end
end
