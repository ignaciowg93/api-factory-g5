class AddRejectionToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :rejection, :string
  end
end
