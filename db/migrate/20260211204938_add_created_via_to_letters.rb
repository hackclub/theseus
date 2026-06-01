class AddCreatedViaToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :created_via, :integer, null: false, default: 0
    add_index :letters, :created_via

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE letters
          SET created_via = CASE
            WHEN letter_queue_id IS NOT NULL AND EXISTS (
              SELECT 1 FROM letter_queues
              WHERE letter_queues.id = letters.letter_queue_id
              AND letter_queues.type = 'Letter::InstantQueue'
            ) THEN 3
            WHEN letter_queue_id IS NOT NULL THEN 2
            WHEN batch_id IS NOT NULL THEN 1
            ELSE 0
          END
        SQL
      end
    end
  end
end
