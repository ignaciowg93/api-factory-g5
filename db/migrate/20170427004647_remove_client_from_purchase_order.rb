class RemoveClientFromPurchaseOrder < ActiveRecord::Migration[5.0]
  def change
    remove_column :purchase_orders, :client_id
  end
end
