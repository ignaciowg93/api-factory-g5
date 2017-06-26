class CreatePromos < ActiveRecord::Migration[5.0]
  def change
    create_table :promos do |t|
      t.string :sku
      t.integer :precio
      t.dateime :inicio
      t.datetime :fin
      t.string :codigo

      t.timestamps
    end
  end
end
