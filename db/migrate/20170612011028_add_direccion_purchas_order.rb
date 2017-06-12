class AddDireccionPurchasOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :direccion, :string
  end
end
