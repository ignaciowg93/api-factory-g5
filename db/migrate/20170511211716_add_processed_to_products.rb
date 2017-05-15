class AddProcessedToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :processed, :integer
  end
end
