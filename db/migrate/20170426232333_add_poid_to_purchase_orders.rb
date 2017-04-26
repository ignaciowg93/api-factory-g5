class AddPoidToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :poid, :string
  end
end
