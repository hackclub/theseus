class AddTargetEmailToImpersonation < ActiveRecord::Migration[8.0]
  def change
    add_column :public_impersonations, :target_email, :string
  end
end
