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



  def create_invoice(po_id)
    # Crea la factura y retorna el objeto JSON.
    3.times do
      factura = HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_factura, json: {oc: po_id})
      if factura.code == 200
        return true
      end
      sleep(20)
    end
    return false
  end

  def rec_invoice(factura_id)
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id, json: {id: factura_id})
      if factura.code == 200
        break
      end
      sleep(20)
    end
    oc_id = factura.parse[0]["oc"]
    oc = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{oc_id}")
    precio_correcto = oc.parse[0]["cantidad"] * oc.parse[0]["precioUnitario"]
    if factura.parse[0]["total"] >= precio_correcto
      #aceptar

    else
      #rechazar
    end



  end

end
