class CreateInvoiceRegs < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_regs do |t|
      t.string :oc_id
      t.integer :status
      t.integer :delivered

      t.timestamps
    end
  end
end
