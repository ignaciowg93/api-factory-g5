class CreatePurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :purchase_orders do |t|
      t.string :payment_method
      t.string :payment_option
      t.datetime :date
      t.references :client, foreign_key: true
      t.string :sku
      t.integer :amount
      t.string :status
      t.datetime :delivery_date
      t.integer :unit_price

      t.timestamps
    end
  end
end
