# == Schema Information
#
# Table name: invoices
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  invoiceid   :string
#  accepted    :boolean
#  rejected    :boolean
#  delivered   :boolean
#  paid        :boolean
#  account     :string
#  price       :integer
#  tax         :integer
#  total_price :integer
#  proveedor   :string
#  cliente     :string
#  date        :datetime
#  po_idtemp   :string
#  boleta      :boolean
#  status      :string
#  amount      :integer
#  sku         :string
#

class Invoice < ApplicationRecord
  belongs_to :purchase_order, optional: true

  validates :invoiceid, uniqueness: true



  def create_invoice(po_id )
    # Crea la factura y retorna el objeto JSON.
  end
end
