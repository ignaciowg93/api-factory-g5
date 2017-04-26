class AddInvoiceIdToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :invoiceid, :string
    add_column :invoices, :accepted, :boolean
    add_column :invoices, :rejected, :boolean
    add_column :invoices, :delivered, :boolean
    add_column :invoices, :paid, :boolean
    add_column :invoices, :account, :string


  end
end
