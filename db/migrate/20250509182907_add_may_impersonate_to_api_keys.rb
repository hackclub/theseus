class AddMayImpersonateToAPIKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :may_impersonate, :boolean
  end
end
