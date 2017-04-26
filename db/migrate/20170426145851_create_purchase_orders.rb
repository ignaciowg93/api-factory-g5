class CreatePurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :purchase_orders do |t|
      t.integer :payment_method
      t.integer :payment_option
      t.datetime :date
      t.references :client, foreign_key: true
      t.string :sku
      t.integer :amount
      t.boolean :status
      t.datetime :delivery_date
      t.integer :unit_price

      t.timestamps
    end
  end
end
