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

ActiveRecord::Schema[8.1].define(version: 2025_11_18_082128) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_mailbox_inbound_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "active_storage_postgresql_files", force: :cascade do |t|
    t.string "key"
    t.oid "oid"
    t.index ["key"], name: "index_active_storage_postgresql_files_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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
    t.boolean "is_discrete", default: false, null: false
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

  create_table "processing_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "finished_at"
    t.jsonb "input_parameters"
    t.jsonb "output_result"
    t.uuid "processable_id"
    t.string "processable_type"
    t.datetime "started_at", null: false
    t.string "tags", default: [], array: true
    t.index ["processable_type", "processable_id"], name: "index_processing_logs_on_processable"
  end

  create_table "quote_check_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "email"
    t.uuid "quote_check_id", null: false
    t.integer "rating"
    t.datetime "updated_at", null: false
    t.string "validation_error_details_id"
    t.index ["quote_check_id"], name: "index_quote_check_feedbacks_on_quote_check_id"
  end

  create_table "quote_checks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "anonymised_text"
    t.string "application_version"
    t.uuid "case_id"
    t.text "comment"
    t.datetime "commented_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "email_subject"
    t.string "email_to"
    t.jsonb "expected_validation_errors"
    t.uuid "file_id"
    t.text "file_markdown"
    t.text "file_text"
    t.datetime "finished_at"
    t.jsonb "metadata"
    t.jsonb "naive_attributes"
    t.string "naive_version"
    t.uuid "parent_id"
    t.jsonb "private_data_qa_attributes"
    t.jsonb "private_data_qa_result"
    t.string "private_data_qa_version"
    t.string "profile", null: false
    t.jsonb "qa_attributes"
    t.jsonb "qa_result"
    t.string "qa_version"
    t.jsonb "read_attributes"
    t.string "reference"
    t.string "renovation_type", default: "geste", null: false
    t.datetime "result_sent_at"
    t.string "source_name", default: "mdso"
    t.datetime "started_at", null: false
    t.text "text"
    t.datetime "updated_at", null: false
    t.jsonb "validation_control_codes"
    t.integer "validation_controls_count"
    t.jsonb "validation_error_details"
    t.datetime "validation_error_edited_at"
    t.jsonb "validation_error_edits"
    t.jsonb "validation_errors"
    t.string "validation_version"
    t.index "\"left\"((qa_result)::text, 1)", name: "index_qa_result_not_null", where: "(qa_result IS NOT NULL)"
    t.index "\"left\"((validation_errors)::text, 1)", name: "index_validation_errors_not_null", where: "(validation_errors IS NOT NULL)"
    t.index ["case_id"], name: "index_quote_checks_on_case_id"
    t.index ["email"], name: "index_quote_checks_on_email"
    t.index ["email_to"], name: "index_quote_checks_on_email_to"
    t.index ["file_id"], name: "index_quote_checks_on_file_id"
    t.index ["finished_at"], name: "index_quote_checks_on_finished_at"
    t.index ["parent_id"], name: "index_quote_checks_on_parent_id"
    t.index ["profile"], name: "index_quote_checks_on_profile"
    t.index ["reference"], name: "index_quote_checks_on_reference"
    t.index ["renovation_type"], name: "index_quote_checks_on_renovation_type"
    t.index ["result_sent_at"], name: "index_quote_checks_on_result_sent_at"
    t.index ["source_name"], name: "index_quote_checks_on_source_name"
    t.index ["started_at"], name: "index_quote_checks_on_started_at"
  end

  create_table "quote_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.binary "data", null: false
    t.string "filename", null: false
    t.boolean "force_ocr", default: false, null: false
    t.string "hexdigest", null: false
    t.text "imagified_pages", array: true
    t.string "ocr"
    t.jsonb "ocr_result"
    t.boolean "security_scan_good"
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", null: false
    t.index "\"left\"((ocr_result)::text, 1)", name: "index_ocr_result_not_null", where: "(ocr_result IS NOT NULL)"
    t.index ["content_type"], name: "index_quote_files_on_content_type"
    t.index ["filename"], name: "index_quote_files_on_filename"
    t.index ["hexdigest", "filename"], name: "index_quote_files_on_hexdigest_and_filename", unique: true
    t.index ["ocr"], name: "index_quote_files_on_ocr"
  end

  create_table "quotes_cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "email_subject"
    t.string "email_to"
    t.datetime "finished_at"
    t.jsonb "metadata"
    t.string "profile", default: "conseiller", null: false
    t.string "reference"
    t.string "renovation_type", default: "ampleur", null: false
    t.string "source_name", default: "mdso"
    t.datetime "updated_at", null: false
    t.jsonb "validation_control_codes"
    t.integer "validation_controls_count"
    t.jsonb "validation_error_details"
    t.datetime "validation_error_edited_at"
    t.jsonb "validation_error_edits"
    t.jsonb "validation_errors"
    t.string "validation_version"
    t.index ["email"], name: "index_quotes_cases_on_email"
    t.index ["email_to"], name: "index_quotes_cases_on_email_to"
    t.index ["reference"], name: "index_quotes_cases_on_reference"
    t.index ["renovation_type"], name: "index_quotes_cases_on_renovation_type"
    t.index ["source_name"], name: "index_quotes_cases_on_source_name"
  end

  create_table "rnt_checks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "quote_check_id"
    t.datetime "result_at"
    t.json "result_json"
    t.datetime "sent_at"
    t.text "sent_input_xml"
    t.index ["quote_check_id"], name: "index_rnt_checks_on_quote_check_id"
    t.index ["sent_at"], name: "index_rnt_checks_on_sent_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "quote_check_feedbacks", "quote_checks"
  add_foreign_key "quote_checks", "quote_files", column: "file_id"
  add_foreign_key "quote_checks", "quotes_cases", column: "case_id"
  add_foreign_key "rnt_checks", "quote_checks"
end
