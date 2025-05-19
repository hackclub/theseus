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

ActiveRecord::Schema[8.0].define(version: 2025_05_19_143542) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.bigint "batch_id"
    t.string "email"
    t.index ["batch_id"], name: "index_addresses_on_batch_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "revoked_at"
    t.boolean "pii"
    t.text "token_ciphertext"
    t.string "token_bidx"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "may_impersonate"
    t.index ["token_bidx"], name: "index_api_keys_on_token_bidx", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "field_mapping"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.bigint "warehouse_template_id"
    t.integer "address_count"
    t.string "warehouse_user_facing_title"
    t.string "aasm_state"
    t.decimal "letter_height"
    t.decimal "letter_width"
    t.decimal "letter_weight"
    t.bigint "letter_mailer_id_id"
    t.bigint "letter_return_address_id"
    t.citext "tags", default: [], array: true
    t.integer "letter_processing_category"
    t.date "letter_mailing_date"
    t.string "template_cycle", default: [], array: true
    t.string "letter_return_address_name"
    t.bigint "letter_queue_id"
    t.index ["letter_mailer_id_id"], name: "index_batches_on_letter_mailer_id_id"
    t.index ["letter_queue_id"], name: "index_batches_on_letter_queue_id"
    t.index ["letter_return_address_id"], name: "index_batches_on_letter_return_address_id"
    t.index ["tags"], name: "index_batches_on_tags", using: :gin
    t.index ["type"], name: "index_batches_on_type"
    t.index ["user_id"], name: "index_batches_on_user_id"
    t.index ["warehouse_template_id"], name: "index_batches_on_warehouse_template_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "common_tags", force: :cascade do |t|
    t.string "tag"
    t.boolean "implies_ysws"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "letter_queues", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "letter_height"
    t.decimal "letter_width"
    t.decimal "letter_weight"
    t.integer "letter_processing_category"
    t.bigint "letter_mailer_id_id"
    t.bigint "letter_return_address_id"
    t.string "letter_return_address_name"
    t.string "user_facing_title"
    t.citext "tags", default: [], array: true
    t.string "type"
    t.string "template"
    t.string "postage_type"
    t.bigint "usps_payment_account_id"
    t.boolean "include_qr_code", default: true
    t.date "letter_mailing_date"
    t.index ["letter_mailer_id_id"], name: "index_letter_queues_on_letter_mailer_id_id"
    t.index ["letter_return_address_id"], name: "index_letter_queues_on_letter_return_address_id"
    t.index ["type"], name: "index_letter_queues_on_type"
    t.index ["user_id"], name: "index_letter_queues_on_user_id"
  end

  create_table "letters", force: :cascade do |t|
    t.integer "processing_category"
    t.text "body"
    t.string "aasm_state"
    t.bigint "usps_mailer_id_id", null: false
    t.decimal "postage"
    t.integer "imb_serial_number"
    t.bigint "address_id", null: false
    t.integer "imb_rollover_count"
    t.string "recipient_email"
    t.decimal "weight"
    t.decimal "width"
    t.decimal "height"
    t.boolean "non_machinable"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rubber_stamps"
    t.bigint "batch_id"
    t.bigint "return_address_id", null: false
    t.jsonb "metadata"
    t.citext "tags", default: [], array: true
    t.integer "postage_type"
    t.date "mailing_date"
    t.datetime "printed_at"
    t.datetime "mailed_at"
    t.datetime "received_at"
    t.string "user_facing_title"
    t.bigint "user_id", null: false
    t.string "return_address_name"
    t.bigint "letter_queue_id"
    t.string "idempotency_key"
    t.index ["address_id"], name: "index_letters_on_address_id"
    t.index ["batch_id"], name: "index_letters_on_batch_id"
    t.index ["idempotency_key"], name: "index_letters_on_idempotency_key", unique: true
    t.index ["imb_serial_number"], name: "index_letters_on_imb_serial_number"
    t.index ["letter_queue_id"], name: "index_letters_on_letter_queue_id"
    t.index ["return_address_id"], name: "index_letters_on_return_address_id"
    t.index ["tags"], name: "index_letters_on_tags", using: :gin
    t.index ["user_id"], name: "index_letters_on_user_id"
    t.index ["usps_mailer_id_id"], name: "index_letters_on_usps_mailer_id_id"
  end

  create_table "public_impersonations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "justification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_email"
    t.index ["user_id"], name: "index_public_impersonations_on_user_id"
  end

  create_table "public_login_codes", force: :cascade do |t|
    t.string "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.datetime "used_at"
    t.index ["user_id"], name: "index_public_login_codes_on_user_id"
  end

  create_table "public_users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "return_addresses", force: :cascade do |t|
    t.string "name"
    t.string "line_1"
    t.string "line_2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.integer "country"
    t.boolean "shared"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_return_addresses_on_user_id"
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
    t.boolean "back_office", default: false
    t.boolean "can_impersonate_public"
    t.bigint "home_mid_id", default: 1, null: false
    t.bigint "home_return_address_id", default: 1, null: false
    t.index ["home_mid_id"], name: "index_users_on_home_mid_id"
    t.index ["home_return_address_id"], name: "index_users_on_home_return_address_id"
  end

  create_table "usps_indicia", force: :cascade do |t|
    t.integer "processing_category"
    t.float "postage_weight"
    t.boolean "nonmachinable"
    t.string "usps_sku"
    t.decimal "postage"
    t.date "mailing_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "usps_payment_account_id", null: false
    t.bigint "letter_id"
    t.jsonb "raw_json_response"
    t.boolean "flirted"
    t.decimal "fees"
    t.index ["letter_id"], name: "index_usps_indicia_on_letter_id"
    t.index ["usps_payment_account_id"], name: "index_usps_indicia_on_usps_payment_account_id"
  end

  create_table "usps_iv_mtr_events", force: :cascade do |t|
    t.datetime "happened_at"
    t.bigint "letter_id"
    t.bigint "batch_id", null: false
    t.jsonb "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "opcode"
    t.string "zip_code"
    t.bigint "mailer_id_id", null: false
    t.index ["batch_id"], name: "index_usps_iv_mtr_events_on_batch_id"
    t.index ["letter_id"], name: "index_usps_iv_mtr_events_on_letter_id"
    t.index ["mailer_id_id"], name: "index_usps_iv_mtr_events_on_mailer_id_id"
  end

  create_table "usps_iv_mtr_raw_json_batches", force: :cascade do |t|
    t.jsonb "payload"
    t.boolean "processed"
    t.string "message_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "usps_mailer_ids", force: :cascade do |t|
    t.string "crid"
    t.string "mid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "rollover_count"
    t.bigint "sequence_number"
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
    t.boolean "ach"
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
    t.bigint "batch_id"
    t.bigint "template_id"
    t.jsonb "metadata"
    t.citext "tags", default: [], array: true
    t.decimal "labor_cost", precision: 10, scale: 2
    t.decimal "contents_cost", precision: 10, scale: 2
    t.index ["address_id"], name: "index_warehouse_orders_on_address_id"
    t.index ["batch_id"], name: "index_warehouse_orders_on_batch_id"
    t.index ["hc_id"], name: "index_warehouse_orders_on_hc_id"
    t.index ["idempotency_key"], name: "index_warehouse_orders_on_idempotency_key", unique: true
    t.index ["source_tag_id"], name: "index_warehouse_orders_on_source_tag_id"
    t.index ["tags"], name: "index_warehouse_orders_on_tags", using: :gin
    t.index ["template_id"], name: "index_warehouse_orders_on_template_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "batches"
  add_foreign_key "api_keys", "users"
  add_foreign_key "batches", "letter_queues"
  add_foreign_key "batches", "return_addresses", column: "letter_return_address_id"
  add_foreign_key "batches", "users"
  add_foreign_key "batches", "usps_mailer_ids", column: "letter_mailer_id_id"
  add_foreign_key "batches", "warehouse_templates"
  add_foreign_key "letter_queues", "return_addresses", column: "letter_return_address_id"
  add_foreign_key "letter_queues", "users"
  add_foreign_key "letter_queues", "usps_mailer_ids", column: "letter_mailer_id_id"
  add_foreign_key "letter_queues", "usps_payment_accounts"
  add_foreign_key "letters", "addresses"
  add_foreign_key "letters", "batches"
  add_foreign_key "letters", "letter_queues"
  add_foreign_key "letters", "return_addresses"
  add_foreign_key "letters", "users"
  add_foreign_key "letters", "usps_mailer_ids"
  add_foreign_key "public_impersonations", "users"
  add_foreign_key "public_login_codes", "public_users", column: "user_id"
  add_foreign_key "return_addresses", "users"
  add_foreign_key "users", "return_addresses", column: "home_return_address_id"
  add_foreign_key "users", "usps_mailer_ids", column: "home_mid_id"
  add_foreign_key "usps_indicia", "letters"
  add_foreign_key "usps_indicia", "usps_payment_accounts"
  add_foreign_key "usps_iv_mtr_events", "letters", on_delete: :nullify
  add_foreign_key "usps_iv_mtr_events", "usps_iv_mtr_raw_json_batches", column: "batch_id"
  add_foreign_key "usps_iv_mtr_events", "usps_mailer_ids", column: "mailer_id_id"
  add_foreign_key "usps_payment_accounts", "usps_mailer_ids"
  add_foreign_key "warehouse_line_items", "warehouse_orders", column: "order_id"
  add_foreign_key "warehouse_line_items", "warehouse_skus", column: "sku_id"
  add_foreign_key "warehouse_line_items", "warehouse_templates", column: "template_id"
  add_foreign_key "warehouse_orders", "addresses"
  add_foreign_key "warehouse_orders", "batches"
  add_foreign_key "warehouse_orders", "source_tags"
  add_foreign_key "warehouse_orders", "users"
  add_foreign_key "warehouse_orders", "warehouse_templates", column: "template_id"
  add_foreign_key "warehouse_templates", "source_tags"
  add_foreign_key "warehouse_templates", "users"
end
