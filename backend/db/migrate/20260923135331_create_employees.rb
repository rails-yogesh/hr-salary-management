class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.string :employee_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :work_email, null: false
      t.references :country, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :job_level, null: false, foreign_key: true
      t.string :job_title, null: false
      t.integer :employment_status, null: false, default: 0
      t.date :hire_date, null: false
      t.date :termination_date

      t.timestamps
    end
    add_index :employees, :employee_number, unique: true
    add_index :employees, :work_email, unique: true
    add_index :employees, :employment_status
    add_index :employees, [:last_name, :first_name]
  end
end
