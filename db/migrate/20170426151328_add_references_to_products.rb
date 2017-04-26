class AddReferencesToProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :products, :warehouse, foreign_key: true
  end
end
