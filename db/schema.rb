# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_22_014230) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "addresses", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "line_1"
    t.string "line_2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.integer "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "source_tags", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.string "owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_id"
    t.string "email"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon_url"
    t.string "username"
    t.boolean "can_warehouse"
  end

  create_table "usps_indicia", force: :cascade do |t|
    t.integer "processing_category"
    t.float "postage_weight"
    t.float "postage_length"
    t.float "postage_height"
    t.float "postage_thickness"
    t.boolean "nonmachinable"
    t.string "usps_sku"
    t.text "raw_usps_response"
    t.decimal "postage"
    t.date "mailing_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "usps_payment_account_id", null: false
    t.index ["usps_payment_account_id"], name: "index_usps_indicia_on_usps_payment_account_id"
  end

  create_table "usps_mailer_ids", force: :cascade do |t|
    t.string "crid"
    t.string "mid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "usps_payment_accounts", force: :cascade do |t|
    t.bigint "usps_mailer_id_id", null: false
    t.integer "account_type"
    t.string "account_number"
    t.string "permit_number"
    t.string "permit_zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "manifest_mid"
    t.index ["usps_mailer_id_id"], name: "index_usps_payment_accounts_on_usps_mailer_id_id"
  end

  create_table "warehouse_line_items", force: :cascade do |t|
    t.integer "quantity"
    t.bigint "sku_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.bigint "template_id"
    t.index ["order_id"], name: "index_warehouse_line_items_on_order_id"
    t.index ["sku_id"], name: "index_warehouse_line_items_on_sku_id"
    t.index ["template_id"], name: "index_warehouse_line_items_on_template_id"
  end

  create_table "warehouse_orders", force: :cascade do |t|
    t.string "hc_id"
    t.bigint "purpose_code_id", null: false
    t.string "aasm_state"
    t.string "recipient_email"
    t.bigint "user_id", null: false
    t.boolean "surprise"
    t.string "user_facing_title"
    t.string "user_facing_description"
    t.text "internal_notes"
    t.integer "zenventory_id"
    t.bigint "source_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id", null: false
    t.datetime "dispatched_at"
    t.datetime "mailed_at"
    t.datetime "canceled_at"
    t.string "carrier"
    t.string "service"
    t.string "tracking_number"
    t.decimal "postage_cost"
    t.decimal "weight"
    t.string "idempotency_key"
    t.boolean "notify_on_dispatch"
    t.index ["address_id"], name: "index_warehouse_orders_on_address_id"
    t.index ["hc_id"], name: "index_warehouse_orders_on_hc_id"
    t.index ["idempotency_key"], name: "index_warehouse_orders_on_idempotency_key", unique: true
    t.index ["purpose_code_id"], name: "index_warehouse_orders_on_purpose_code_id"
    t.index ["source_tag_id"], name: "index_warehouse_orders_on_source_tag_id"
    t.index ["user_id"], name: "index_warehouse_orders_on_user_id"
  end

  create_table "warehouse_purpose_codes", force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence_number"
    t.index ["code"], name: "index_warehouse_purpose_codes_on_code"
  end

  create_table "warehouse_skus", force: :cascade do |t|
    t.string "sku"
    t.text "description"
    t.decimal "average_po_cost"
    t.text "customs_description"
    t.integer "in_stock"
    t.boolean "ai_enabled"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hs_code"
    t.string "country_of_origin"
    t.integer "category"
    t.string "name"
    t.decimal "actual_cost_to_hc"
    t.decimal "declared_unit_cost_override"
    t.string "zenventory_id"
    t.integer "inbound"
    t.index ["sku"], name: "index_warehouse_skus_on_sku", unique: true
  end

  create_table "warehouse_templates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.bigint "source_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public"
    t.index ["source_tag_id"], name: "index_warehouse_templates_on_source_tag_id"
    t.index ["user_id"], name: "index_warehouse_templates_on_user_id"
  end

  add_foreign_key "usps_indicia", "usps_payment_accounts"
  add_foreign_key "usps_payment_accounts", "usps_mailer_ids"
  add_foreign_key "warehouse_line_items", "warehouse_orders", column: "order_id"
  add_foreign_key "warehouse_line_items", "warehouse_skus", column: "sku_id"
  add_foreign_key "warehouse_line_items", "warehouse_templates", column: "template_id"
  add_foreign_key "warehouse_orders", "addresses"
  add_foreign_key "warehouse_orders", "source_tags"
  add_foreign_key "warehouse_orders", "users"
  add_foreign_key "warehouse_orders", "warehouse_purpose_codes", column: "purpose_code_id"
  add_foreign_key "warehouse_templates", "source_tags"
  add_foreign_key "warehouse_templates", "users"
end
