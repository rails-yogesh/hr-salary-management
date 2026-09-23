class CreateJobLevels < ActiveRecord::Migration[7.2]
  def change
    create_table :job_levels do |t|
      t.string :name, null: false
      t.integer :rank, null: false

      t.timestamps
    end
    add_index :job_levels, :name, unique: true
    add_index :job_levels, :rank, unique: true
  end
end
