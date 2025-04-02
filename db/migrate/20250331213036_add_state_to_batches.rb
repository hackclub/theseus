class AddStateToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :aasm_state, :string
  end
end
