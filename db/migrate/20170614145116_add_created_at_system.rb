class AddCreatedAtSystem < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :created_at_system, :datetime
  end
end
