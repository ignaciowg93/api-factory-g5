class AddSellPriceToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :sell_price, :int
  end
end
