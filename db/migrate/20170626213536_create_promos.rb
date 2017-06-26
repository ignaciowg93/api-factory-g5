class CreatePromos < ActiveRecord::Migration[5.0]
  def change
    create_table :promos do |t|
      t.string :sku
      t.integer :precio
      t.datetime :inicio
      t.datetime :fin
      t.string :codigo

      t.timestamps
    end
  end
end
