class CreateSupplies < ActiveRecord::Migration[5.0]
  def change
    create_table :supplies do |t|
      t.string :sku
      t.integer :requierment
      t.string :seller
      t.decimal :time
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
