class RemoveDefaultFromBatches < ActiveRecord::Migration[8.0]
  def change
    change_column_default :batches, :type, nil
  end
end
