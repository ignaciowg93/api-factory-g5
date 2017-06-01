class AddStockReservadoToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :stock_reservado, :integer
  end
end
