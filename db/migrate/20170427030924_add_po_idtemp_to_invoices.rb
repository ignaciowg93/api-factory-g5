class AddPoIdtempToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :po_idtemp, :string
  end
end
