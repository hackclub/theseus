class AddUserToLetter < ActiveRecord::Migration[8.0]
  def change
    # First add the column as nullable
    add_reference :letters, :user, null: true, foreign_key: true
    
    # Then set all null user_ids to user with id 1
    execute "UPDATE letters SET user_id = 1 WHERE user_id IS NULL"
    
    # Finally add the non-null constraint
    change_column_null :letters, :user_id, false
  end
end
