class AddProcessOptionsToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :process_options, :jsonb
    add_column :batches, :process_error, :string
  end
end
