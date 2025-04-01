class RenameBatchTypeToType < ActiveRecord::Migration[7.1]
  def change
    rename_column :batches, :batch_type, :type
  end
end
