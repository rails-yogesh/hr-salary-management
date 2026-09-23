class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :currency_code, null: false, limit: 3

      t.timestamps
    end
    add_index :countries, :code, unique: true
  end
end
