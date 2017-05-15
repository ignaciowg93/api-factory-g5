class AddFieldsToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :lot, :integer
    add_column :products, :ingredients, :integer
    add_column :products, :dependent, :integer
    add_column :products, :time, :decimal
  end
end
