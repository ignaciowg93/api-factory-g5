class CreateWarehouses < ActiveRecord::Migration[5.0]
  def change
    create_table :warehouses do |t|
      t.integer :type
      t.integer :capacity

      t.timestamps
    end
  end
end
