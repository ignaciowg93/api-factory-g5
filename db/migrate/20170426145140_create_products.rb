class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :name
       t.decimal :price ,:precision=>64, :scale=>12

      t.timestamps
    end
  end
end
