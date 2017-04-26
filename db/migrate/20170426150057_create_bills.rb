class CreateBills < ActiveRecord::Migration[5.0]
  def change
    create_table :bills do |t|
      t.datetime :date
      t.references :client, foreign_key: true
      t.integer :price
      t.integer :tax
      t.integer :total_price
      t.integer :status
      t.references :purchase_order, foreign_key: true

      t.timestamps
    end
  end
end
