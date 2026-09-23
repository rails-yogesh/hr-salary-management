class CreateDepartments < ActiveRecord::Migration[7.2]
  def change
    create_table :departments do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :departments, :name, unique: true
  end
end
