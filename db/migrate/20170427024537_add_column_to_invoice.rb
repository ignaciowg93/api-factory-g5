class AddColumnToInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :price, :integer
    add_column :invoices, :tax, :integer
    add_column :invoices, :total_price, :integer
    add_column :invoices, :proveedor, :string
    add_column :invoices, :cliente, :string
    add_column :invoices, :date, :datetime
  end
end
