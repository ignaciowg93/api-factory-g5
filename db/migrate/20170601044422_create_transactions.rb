class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.string :_id
      t.string :origin
      t.string :destiny
      t.decimal :amount
      t.boolean :state

      t.timestamps
    end
  end
end
