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

ActiveRecord::Schema[7.2].define(version: 2026_09_23_135339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "compensation_records", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "amount_cents", null: false
    t.string "currency_code", limit: 3, null: false
    t.integer "pay_frequency", null: false
    t.date "effective_date", null: false
    t.date "end_date"
    t.integer "change_reason", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "effective_date"], name: "index_compensation_records_on_employee_id_and_effective_date"
    t.index ["employee_id"], name: "index_compensation_records_on_employee_id"
    t.index ["employee_id"], name: "index_compensation_records_on_employee_id_current", unique: true, where: "(end_date IS NULL)"
  end

  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "work_email", null: false
    t.bigint "country_id", null: false
    t.bigint "department_id", null: false
    t.bigint "job_level_id", null: false
    t.string "job_title", null: false
    t.integer "employment_status", default: 0, null: false
    t.date "hire_date", null: false
    t.date "termination_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
    t.index ["employment_status"], name: "index_employees_on_employment_status"
    t.index ["job_level_id"], name: "index_employees_on_job_level_id"
    t.index ["last_name", "first_name"], name: "index_employees_on_last_name_and_first_name"
    t.index ["work_email"], name: "index_employees_on_work_email", unique: true
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency_code", limit: 3, null: false
    t.decimal "rate_to_usd", precision: 12, scale: 6, null: false
    t.date "as_of_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_code"], name: "index_exchange_rates_on_currency_code", unique: true
  end

  create_table "job_levels", force: :cascade do |t|
    t.string "name", null: false
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_job_levels_on_name", unique: true
    t.index ["rank"], name: "index_job_levels_on_rank", unique: true
  end

  add_foreign_key "compensation_records", "employees"
  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_levels"
end
