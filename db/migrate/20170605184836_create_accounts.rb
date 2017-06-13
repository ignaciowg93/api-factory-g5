class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :invoice_id
      t.string :_id
      t.string :tipo
      t.boolean :paid
      t.datetime :date_to_pay
      t.boolean :cuota
      t.integer :amount

      t.timestamps
    end
  end
end
