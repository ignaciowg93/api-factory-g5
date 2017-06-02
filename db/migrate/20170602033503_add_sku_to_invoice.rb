class AddSkuToInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :sku, :string
  end
end
