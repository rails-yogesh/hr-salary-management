class CreateCompensationRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :compensation_records do |t|
      t.references :employee, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency_code, null: false, limit: 3
      t.integer :pay_frequency, null: false
      t.date :effective_date, null: false
      t.date :end_date
      t.integer :change_reason, null: false
      t.string :note

      t.timestamps
    end

    add_index :compensation_records, [ :employee_id, :effective_date ]

    # A "current" compensation record is one with end_date IS NULL. This partial
    # unique index is the DB-level guarantee behind the append-only history
    # invariant: an employee can have at most one current record at a time.
    add_index :compensation_records, :employee_id,
      unique: true,
      where: "end_date IS NULL",
      name: "index_compensation_records_on_employee_id_current"
  end
end
