class AddStockReservadoToSupplies < ActiveRecord::Migration[5.0]
  def change
    add_column :supplies, :stock_reservado, :integer
  end
end
