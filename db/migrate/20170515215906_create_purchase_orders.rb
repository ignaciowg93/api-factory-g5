class CreatePurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :purchase_orders do |t|
      t.string :_id
      t.string :client
      t.string :supplier
      t.string :sku
      t.datetime :delivery_date
      t.integer :amount
      t.integer :delivered_qt
      t.integer :unit_price
      t.string :channel
      t.string :status
      t.string :notes
      t.string :rejection
      t.string :anullment

      t.timestamps
    end
  end
end
