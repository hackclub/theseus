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

ActiveRecord::Schema[8.1].define(version: 2026_09_09_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "batch_id"
    t.string "city"
    t.integer "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.uuid "import_token"
    t.string "last_name"
    t.string "line_1"
    t.string "line_2"
    t.string "phone_number"
    t.string "postal_code"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_addresses_on_batch_id"
    t.index ["import_token"], name: "index_addresses_on_import_token", where: "(import_token IS NOT NULL)"
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "billing_profile_id"
    t.datetime "created_at", null: false
    t.boolean "may_impersonate"
    t.string "name"
    t.boolean "pii"
    t.boolean "qz_only"
    t.datetime "revoked_at"
    t.string "token_bidx"
    t.text "token_ciphertext"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["billing_profile_id"], name: "index_api_keys_on_billing_profile_id"
    t.index ["token_bidx"], name: "index_api_keys_on_token_bidx", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "aasm_state"
    t.integer "address_count"
    t.jsonb "audit_log"
    t.datetime "created_at", null: false
    t.jsonb "field_mapping"
    t.bigint "hcb_payment_account_id"
    t.string "hcb_transfer_id"
    t.decimal "letter_height"
    t.bigint "letter_mailer_id_id"
    t.date "letter_mailing_date"
    t.integer "letter_processing_category"
    t.bigint "letter_queue_id"
    t.bigint "letter_return_address_id"
    t.string "letter_return_address_name"
    t.decimal "letter_weight"
    t.decimal "letter_width"
    t.string "process_error"
    t.jsonb "process_options"
    t.citext "tags", default: [], array: true
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "warehouse_template_id"
    t.string "warehouse_user_facing_title"
    t.index ["aasm_state"], name: "index_batches_on_aasm_state"
    t.index ["hcb_payment_account_id"], name: "index_batches_on_hcb_payment_account_id"
    t.index ["letter_mailer_id_id"], name: "index_batches_on_letter_mailer_id_id"
    t.index ["letter_queue_id"], name: "index_batches_on_letter_queue_id"
    t.index ["letter_return_address_id"], name: "index_batches_on_letter_return_address_id"
    t.index ["tags"], name: "index_batches_on_tags", using: :gin
    t.index ["type"], name: "index_batches_on_type"
    t.index ["user_id"], name: "index_batches_on_user_id"
    t.index ["warehouse_template_id"], name: "index_batches_on_warehouse_template_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "common_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "implies_ysws"
    t.string "tag"
    t.datetime "updated_at", null: false
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
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

  create_table "hcb_oauth_connections", force: :cascade do |t|
    t.text "access_token_ciphertext"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "invalidated_at"
    t.text "refresh_token_ciphertext"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_hcb_oauth_connections_on_user_id"
  end

  create_table "hcb_payment_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "hcb_oauth_connection_id", null: false
    t.string "organization_id"
    t.string "organization_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["hcb_oauth_connection_id"], name: "index_hcb_payment_accounts_on_hcb_oauth_connection_id"
    t.index ["organization_id"], name: "index_hcb_payment_accounts_on_organization_id"
    t.index ["user_id"], name: "index_hcb_payment_accounts_on_user_id"
  end

  create_table "hcb_transfers", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "attempts", default: 0, null: false
    t.bigint "billing_profile_id", null: false
    t.datetime "created_at", null: false
    t.integer "direction", default: 0, null: false
    t.string "hq_organization_id", null: false
    t.string "idempotency_key", null: false
    t.datetime "last_attempted_at"
    t.string "last_error"
    t.text "memo"
    t.jsonb "metadata", default: {}
    t.string "name"
    t.datetime "next_attempt_at"
    t.string "remote_id"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["billing_profile_id"], name: "index_hcb_transfers_on_billing_profile_id"
    t.index ["hq_organization_id"], name: "index_hcb_transfers_on_hq_organization_id"
    t.index ["idempotency_key"], name: "index_hcb_transfers_on_idempotency_key", unique: true
    t.index ["remote_id"], name: "index_hcb_transfers_on_remote_id"
    t.index ["state", "next_attempt_at"], name: "index_hcb_transfers_on_state_and_next_attempt_at"
    t.index ["state"], name: "index_hcb_transfers_on_state"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "billing_profile_id", null: false
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.bigint "hcb_transfer_id"
    t.bigint "ledgerable_id", null: false
    t.string "ledgerable_type", null: false
    t.jsonb "metadata", default: {}
    t.bigint "reverses_id"
    t.datetime "settled_at"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["billing_profile_id", "state"], name: "index_ledger_entries_on_billing_profile_id_and_state"
    t.index ["billing_profile_id"], name: "index_ledger_entries_on_billing_profile_id"
    t.index ["category"], name: "index_ledger_entries_on_category"
    t.index ["hcb_transfer_id"], name: "index_ledger_entries_on_hcb_transfer_id"
    t.index ["ledgerable_type", "ledgerable_id"], name: "index_ledger_entries_on_ledgerable"
    t.index ["reverses_id"], name: "index_ledger_entries_on_reverses_id"
    t.index ["state", "hcb_transfer_id"], name: "index_ledger_entries_unclaimed"
    t.index ["state"], name: "index_ledger_entries_on_state"
    t.check_constraint "amount_cents <> 0", name: "ledger_entries_amount_nonzero"
  end

  create_table "letter_queues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "hcb_payment_account_id"
    t.boolean "include_qr_code", default: true
    t.decimal "letter_height"
    t.bigint "letter_mailer_id_id"
    t.date "letter_mailing_date"
    t.integer "letter_processing_category"
    t.bigint "letter_return_address_id"
    t.string "letter_return_address_name"
    t.decimal "letter_weight"
    t.decimal "letter_width"
    t.string "name"
    t.string "postage_type"
    t.string "slug"
    t.citext "tags", default: [], array: true
    t.string "template"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "user_facing_title"
    t.bigint "user_id", null: false
    t.bigint "usps_payment_account_id"
    t.index ["hcb_payment_account_id"], name: "index_letter_queues_on_hcb_payment_account_id"
    t.index ["letter_mailer_id_id"], name: "index_letter_queues_on_letter_mailer_id_id"
    t.index ["letter_return_address_id"], name: "index_letter_queues_on_letter_return_address_id"
    t.index ["type"], name: "index_letter_queues_on_type"
    t.index ["user_id"], name: "index_letter_queues_on_user_id"
  end

  create_table "letters", force: :cascade do |t|
    t.string "aasm_state"
    t.bigint "address_id", null: false
    t.bigint "batch_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "created_via", default: 0, null: false
    t.decimal "height"
    t.string "idempotency_key"
    t.integer "imb_rollover_count"
    t.integer "imb_serial_number"
    t.string "indicia_error"
    t.string "indicia_state"
    t.bigint "letter_queue_id"
    t.datetime "mailed_at"
    t.date "mailing_date"
    t.jsonb "metadata"
    t.boolean "non_machinable"
    t.decimal "postage"
    t.integer "postage_type"
    t.datetime "printed_at"
    t.integer "processing_category"
    t.datetime "received_at"
    t.string "recipient_email"
    t.bigint "return_address_id", null: false
    t.string "return_address_name"
    t.text "rubber_stamps"
    t.citext "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.string "user_facing_title"
    t.bigint "user_id", null: false
    t.bigint "usps_mailer_id_id", null: false
    t.decimal "weight"
    t.decimal "width"
    t.index ["aasm_state"], name: "index_letters_on_aasm_state"
    t.index ["address_id"], name: "index_letters_on_address_id"
    t.index ["batch_id"], name: "index_letters_on_batch_id"
    t.index ["created_via"], name: "index_letters_on_created_via"
    t.index ["idempotency_key"], name: "index_letters_on_idempotency_key", unique: true
    t.index ["imb_serial_number"], name: "index_letters_on_imb_serial_number"
    t.index ["letter_queue_id"], name: "index_letters_on_letter_queue_id"
    t.index ["return_address_id"], name: "index_letters_on_return_address_id"
    t.index ["tags"], name: "index_letters_on_tags", using: :gin
    t.index ["user_id"], name: "index_letters_on_user_id"
    t.index ["usps_mailer_id_id"], name: "index_letters_on_usps_mailer_id_id"
  end

  create_table "public_api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "public_user_id", null: false
    t.datetime "revoked_at"
    t.string "token_bidx"
    t.string "token_ciphertext"
    t.datetime "updated_at", null: false
    t.index ["public_user_id"], name: "index_public_api_keys_on_public_user_id"
    t.index ["token_bidx"], name: "index_public_api_keys_on_token_bidx", unique: true
  end

  create_table "public_impersonations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "justification"
    t.string "target_email"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_public_impersonations_on_user_id"
  end

  create_table "public_login_codes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "token"
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_public_login_codes_on_user_id"
  end

  create_table "public_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "hca_id"
    t.boolean "opted_out_of_map", default: false
    t.datetime "updated_at", null: false
    t.index ["hca_id"], name: "index_public_users_on_hca_id", unique: true
  end

  create_table "return_addresses", force: :cascade do |t|
    t.string "city"
    t.integer "country"
    t.datetime "created_at", null: false
    t.string "line_1"
    t.string "line_2"
    t.string "name"
    t.string "postal_code"
    t.boolean "shared"
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_return_addresses_on_user_id"
  end

  create_table "toolchest_oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "mount_key", default: "default", null: false
    t.text "redirect_uri", null: false
    t.string "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_toolchest_oauth_access_grants_on_application_id"
    t.index ["token_digest"], name: "index_toolchest_oauth_access_grants_on_token_digest", unique: true
  end

  create_table "toolchest_oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "mount_key", default: "default", null: false
    t.string "refresh_token"
    t.string "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_toolchest_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_toolchest_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["token"], name: "index_toolchest_oauth_access_tokens_on_token", unique: true
  end

  create_table "toolchest_oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_toolchest_oauth_applications_on_uid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "can_impersonate_public"
    t.boolean "can_use_indicia", default: false, null: false
    t.boolean "can_warehouse"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "hca_id"
    t.bigint "home_mid_id", default: 1, null: false
    t.bigint "home_return_address_id", default: 1, null: false
    t.string "icon_url"
    t.boolean "is_admin"
    t.boolean "is_warehouse_czar", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.string "slack_id"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["hca_id"], name: "index_users_on_hca_id", unique: true
    t.index ["home_mid_id"], name: "index_users_on_home_mid_id"
    t.index ["home_return_address_id"], name: "index_users_on_home_return_address_id"
  end

  create_table "usps_indicia", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "fees"
    t.boolean "flirted"
    t.bigint "hcb_payment_account_id"
    t.string "hcb_transfer_id"
    t.bigint "letter_id"
    t.date "mailing_date"
    t.boolean "nonmachinable"
    t.decimal "postage"
    t.float "postage_weight"
    t.integer "processing_category"
    t.jsonb "raw_json_response"
    t.datetime "updated_at", null: false
    t.bigint "usps_payment_account_id", null: false
    t.string "usps_sku"
    t.index ["hcb_payment_account_id"], name: "index_usps_indicia_on_hcb_payment_account_id"
    t.index ["letter_id"], name: "index_usps_indicia_on_letter_id"
    t.index ["usps_payment_account_id"], name: "index_usps_indicia_on_usps_payment_account_id"
  end

  create_table "usps_iv_mtr_events", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "happened_at"
    t.bigint "letter_id"
    t.bigint "mailer_id_id", null: false
    t.string "opcode"
    t.jsonb "payload"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["batch_id"], name: "index_usps_iv_mtr_events_on_batch_id"
    t.index ["letter_id"], name: "index_usps_iv_mtr_events_on_letter_id"
    t.index ["mailer_id_id", "happened_at"], name: "index_usps_iv_mtr_events_on_mailer_id_id_and_happened_at"
    t.index ["mailer_id_id", "opcode"], name: "index_usps_iv_mtr_events_on_mailer_id_id_and_opcode"
    t.index ["mailer_id_id"], name: "index_usps_iv_mtr_events_on_mailer_id_id"
  end

  create_table "usps_iv_mtr_raw_json_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_group_id"
    t.jsonb "payload"
    t.boolean "processed"
    t.datetime "updated_at", null: false
  end

  create_table "usps_mailer_ids", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crid"
    t.string "mid"
    t.string "name"
    t.integer "rollover_count"
    t.bigint "sequence_number"
    t.datetime "updated_at", null: false
  end

  create_table "usps_payment_accounts", force: :cascade do |t|
    t.string "account_number"
    t.integer "account_type"
    t.boolean "ach"
    t.datetime "created_at", null: false
    t.string "manifest_mid"
    t.string "name"
    t.string "permit_number"
    t.string "permit_zip"
    t.datetime "updated_at", null: false
    t.bigint "usps_mailer_id_id", null: false
    t.index ["usps_mailer_id_id"], name: "index_usps_payment_accounts_on_usps_mailer_id_id"
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "api_key_id"
    t.datetime "created_at"
    t.string "event", null: false
    t.inet "ip"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "warehouse_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id"
    t.integer "quantity"
    t.bigint "sku_id", null: false
    t.bigint "template_id"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_warehouse_line_items_on_order_id"
    t.index ["sku_id"], name: "index_warehouse_line_items_on_sku_id"
    t.index ["template_id"], name: "index_warehouse_line_items_on_template_id"
  end

  create_table "warehouse_orders", force: :cascade do |t|
    t.string "aasm_state"
    t.bigint "address_id", null: false
    t.bigint "batch_id"
    t.bigint "billing_profile_id"
    t.datetime "canceled_at"
    t.string "carrier"
    t.decimal "contents_cost", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.integer "created_via", default: 0, null: false
    t.datetime "dispatched_at"
    t.string "hc_id"
    t.string "idempotency_key"
    t.text "internal_notes"
    t.decimal "labor_cost", precision: 10, scale: 2
    t.datetime "mailed_at"
    t.jsonb "metadata"
    t.boolean "notify_on_dispatch"
    t.bigint "origin_batch_id"
    t.decimal "postage_cost"
    t.string "recipient_email"
    t.string "service"
    t.boolean "surprise"
    t.citext "tags", default: [], array: true
    t.bigint "template_id"
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.string "user_facing_description"
    t.string "user_facing_title"
    t.bigint "user_id", null: false
    t.decimal "weight"
    t.integer "zenventory_id"
    t.index ["aasm_state"], name: "index_warehouse_orders_on_aasm_state"
    t.index ["address_id"], name: "index_warehouse_orders_on_address_id"
    t.index ["batch_id"], name: "index_warehouse_orders_on_batch_id"
    t.index ["billing_profile_id"], name: "index_warehouse_orders_on_billing_profile_id"
    t.index ["created_via"], name: "index_warehouse_orders_on_created_via"
    t.index ["hc_id"], name: "index_warehouse_orders_on_hc_id"
    t.index ["idempotency_key"], name: "index_warehouse_orders_on_idempotency_key", unique: true
    t.index ["origin_batch_id"], name: "index_warehouse_orders_on_origin_batch_id"
    t.index ["tags"], name: "index_warehouse_orders_on_tags", using: :gin
    t.index ["template_id"], name: "index_warehouse_orders_on_template_id"
    t.index ["user_id"], name: "index_warehouse_orders_on_user_id"
    t.index ["zenventory_id"], name: "index_warehouse_orders_on_zenventory_id"
  end

  create_table "warehouse_purchase_order_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "purchase_order_id", null: false
    t.integer "quantity", null: false
    t.bigint "sku_id"
    t.bigint "sku_request_id"
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["purchase_order_id"], name: "index_warehouse_purchase_order_line_items_on_purchase_order_id"
    t.index ["sku_id"], name: "index_warehouse_purchase_order_line_items_on_sku_id"
    t.index ["sku_request_id"], name: "index_warehouse_purchase_order_line_items_on_sku_request_id"
  end

  create_table "warehouse_purchase_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "order_number"
    t.date "required_by_date"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "reviewer_notes"
    t.string "status", default: "draft"
    t.datetime "submitted_at"
    t.integer "supplier_id"
    t.string "supplier_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "zenventory_id"
    t.index ["order_number"], name: "index_warehouse_purchase_orders_on_order_number"
    t.index ["reviewed_by_id"], name: "index_warehouse_purchase_orders_on_reviewed_by_id"
    t.index ["user_id"], name: "index_warehouse_purchase_orders_on_user_id"
    t.index ["zenventory_id"], name: "index_warehouse_purchase_orders_on_zenventory_id", unique: true
  end

  create_table "warehouse_purpose_codes", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "sequence_number"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_warehouse_purpose_codes_on_code"
  end

  create_table "warehouse_sku_requests", force: :cascade do |t|
    t.string "aasm_state", default: "draft", null: false
    t.string "assigned_sku_code"
    t.string "category"
    t.string "country_of_origin"
    t.datetime "created_at", null: false
    t.text "customs_description"
    t.text "description"
    t.date "expected_arrival"
    t.integer "expected_quantity"
    t.string "hs_code"
    t.string "name", null: false
    t.string "program"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "reviewer_notes"
    t.datetime "submitted_at"
    t.string "suggested_sku_code"
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "warehouse_sku_id"
    t.index ["aasm_state"], name: "index_warehouse_sku_requests_on_aasm_state"
    t.index ["reviewed_by_id"], name: "index_warehouse_sku_requests_on_reviewed_by_id"
    t.index ["user_id"], name: "index_warehouse_sku_requests_on_user_id"
    t.index ["warehouse_sku_id"], name: "index_warehouse_sku_requests_on_warehouse_sku_id"
  end

  create_table "warehouse_skus", force: :cascade do |t|
    t.decimal "actual_cost_to_hc"
    t.boolean "ai_enabled"
    t.decimal "average_po_cost"
    t.integer "category"
    t.string "country_of_origin"
    t.datetime "created_at", null: false
    t.text "customs_description"
    t.decimal "declared_unit_cost_override"
    t.text "description"
    t.boolean "enabled"
    t.string "hs_code"
    t.integer "in_stock"
    t.integer "inbound"
    t.string "name"
    t.string "sku"
    t.datetime "updated_at", null: false
    t.string "zenventory_id"
    t.index ["sku"], name: "index_warehouse_skus_on_sku", unique: true
  end

  create_table "warehouse_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "public"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_warehouse_templates_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "batches"
  add_foreign_key "api_keys", "hcb_payment_accounts", column: "billing_profile_id"
  add_foreign_key "api_keys", "users"
  add_foreign_key "batches", "hcb_payment_accounts"
  add_foreign_key "batches", "letter_queues"
  add_foreign_key "batches", "return_addresses", column: "letter_return_address_id"
  add_foreign_key "batches", "users"
  add_foreign_key "batches", "usps_mailer_ids", column: "letter_mailer_id_id"
  add_foreign_key "batches", "warehouse_templates"
  add_foreign_key "hcb_oauth_connections", "users"
  add_foreign_key "hcb_payment_accounts", "hcb_oauth_connections"
  add_foreign_key "hcb_payment_accounts", "users"
  add_foreign_key "hcb_transfers", "hcb_payment_accounts", column: "billing_profile_id"
  add_foreign_key "ledger_entries", "hcb_payment_accounts", column: "billing_profile_id"
  add_foreign_key "ledger_entries", "hcb_transfers"
  add_foreign_key "ledger_entries", "ledger_entries", column: "reverses_id"
  add_foreign_key "letter_queues", "hcb_payment_accounts"
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
  add_foreign_key "public_api_keys", "public_users"
  add_foreign_key "public_impersonations", "users"
  add_foreign_key "public_login_codes", "public_users", column: "user_id"
  add_foreign_key "return_addresses", "users"
  add_foreign_key "toolchest_oauth_access_grants", "toolchest_oauth_applications", column: "application_id"
  add_foreign_key "toolchest_oauth_access_tokens", "toolchest_oauth_applications", column: "application_id"
  add_foreign_key "users", "return_addresses", column: "home_return_address_id"
  add_foreign_key "users", "usps_mailer_ids", column: "home_mid_id"
  add_foreign_key "usps_indicia", "hcb_payment_accounts"
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
  add_foreign_key "warehouse_orders", "batches", column: "origin_batch_id"
  add_foreign_key "warehouse_orders", "hcb_payment_accounts", column: "billing_profile_id"
  add_foreign_key "warehouse_orders", "users"
  add_foreign_key "warehouse_orders", "warehouse_templates", column: "template_id"
  add_foreign_key "warehouse_purchase_order_line_items", "warehouse_purchase_orders", column: "purchase_order_id"
  add_foreign_key "warehouse_purchase_order_line_items", "warehouse_sku_requests", column: "sku_request_id"
  add_foreign_key "warehouse_purchase_order_line_items", "warehouse_skus", column: "sku_id"
  add_foreign_key "warehouse_purchase_orders", "users"
  add_foreign_key "warehouse_purchase_orders", "users", column: "reviewed_by_id"
  add_foreign_key "warehouse_sku_requests", "users"
  add_foreign_key "warehouse_sku_requests", "users", column: "reviewed_by_id"
  add_foreign_key "warehouse_sku_requests", "warehouse_skus"
  add_foreign_key "warehouse_templates", "users"
end
