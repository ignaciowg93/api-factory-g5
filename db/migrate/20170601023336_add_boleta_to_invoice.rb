class AddBoletaToInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :boleta, :boolean
  end
end
