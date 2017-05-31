class CreateProductionOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :production_orders do |t|
      t.string :sku
      t.integer :amount

      t.timestamps
    end
  end
end
