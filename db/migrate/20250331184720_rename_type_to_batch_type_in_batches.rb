class RenameTypeToBatchTypeInBatches < ActiveRecord::Migration[7.1]
  def change
    rename_column :batches, :type, :batch_type
  end
end
