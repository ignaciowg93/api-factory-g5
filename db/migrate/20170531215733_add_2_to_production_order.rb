class Add2ToProductionOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :production_orders, :oc_id, :string
    add_column :production_orders, :est_date, :string
  end
end
