class CreateExchangeRates < ActiveRecord::Migration[7.2]
  def change
    create_table :exchange_rates do |t|
      t.string :currency_code, null: false, limit: 3
      t.decimal :rate_to_usd, null: false, precision: 12, scale: 6
      t.date :as_of_date, null: false

      t.timestamps
    end
    add_index :exchange_rates, :currency_code, unique: true
  end
end
