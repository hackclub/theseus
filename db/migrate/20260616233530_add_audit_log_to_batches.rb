class AddAuditLogToBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :audit_log, :jsonb
  end
end
