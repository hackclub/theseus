# Deferred migrations

Migrations in this directory are **not** run by `bin/rails db:migrate` — this
path is deliberately not in `ActiveRecord::Migrator.migrations_paths`.

They live here because they are destructive to code that is still running.
During a rolling deploy, old and new processes serve traffic at the same time.
A migration that drops a table or column the *old* code still reads will take
down those old processes for the length of the rollout (and permanently, if the
deploy has to be rolled back).

The pattern is:

1. Ship the schema-compatible half in `db/migrate` (make columns nullable, stop
   writing them, drop the model).
2. Deploy and let it fully roll out. Confirm no old processes remain.
3. Move the deferred file into `db/migrate` — keep the filename/timestamp, or
   restamp it to now if a later migration has already landed — and run
   `bin/rails db:migrate`. Commit the resulting `db/schema.rb`.

Do not move a file out of here as part of the same deploy that introduced it.

## Pending

- `20260910000000_drop_source_tags.rb` — drops `source_tags` and the
  `warehouse_orders.source_tag_id` / `warehouse_templates.source_tag_id`
  columns. Waits on the ui2-fr deploy, whose predecessor still reads them.
