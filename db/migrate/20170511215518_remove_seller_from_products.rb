class RemoveSellerFromProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :seller, :string
  end
end
