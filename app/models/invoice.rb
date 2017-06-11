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



  def self.create_invoice(po_id, boleta)
    # Crea la factura y retorna el objeto JSON.
    3.times do
      factura = HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_factura, json: {oc: po_id})
      if factura.code == 200
        fact = factura.parse
        fact_temp = Invoice.new

        fact_temp.invoiceid = fact["_id"]
        fact_temp.accepted = false
        fact_temp.rejected = false
        fact_temp.delivered = false
        fact_temp.paid =  false
        fact_temp.price = fact["bruto"]
        fact_temp.tax = fact["iva"]
        fact_temp.total_price = fact["total"]
        fact_temp.proveedor = fact["proveedor"]
        fact_temp.cliente = fact["cliente"]
        fact_temp.po_idtemp = po_id
        fact_temp.boleta = boleta
        fact_temp.status = fact["estado"]
        fact_temp.amount = fact["oc"]["cantidad"]
        fact_temp.sku = fact["oc"]["sku"]
        if fact_temp.save!
          return true
        end
      end
      sleep(20)
    end
    return false
  end

  def self.rec_invoice(factura_id, cuenta_banco)
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id, json: {id: factura_id})
      if factura.code == 200
        break
      end
      sleep(20)
    end
    if factura.code == 200
      render json:{ok: "Factura recibida exitosamente"} , status:200
      Thread.new do
        oc_id = factura.parse[0]["oc"]
        oc = PurchaseOrder.find_by(_id: oc_id)
        #oc = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{oc_id}")
        precio_correcto = oc.amount * oc.unit_price
        #precio_correcto = oc.parse[0]["cantidad"] * oc.parse[0]["precioUnitario"]
        fact = factura.parse[0]
        inv = Invoice.new

        inv.invoiceid = factura_id
        inv.accepted = false
        inv.rejected = false
        inv.delivered = false
        inv.paid =  false
        inv.price = fact["bruto"]
        inv.tax = fact["iva"]
        inv.total_price = fact["total"]
        inv.proveedor = fact["proveedor"]
        inv.cliente = fact["cliente"]
        inv.po_idtemp = fact["oc"]
        inv.status = fact["estado"]
        inv.save!

        cliente = factura.parse[0]["cliente"]
        if factura.parse[0]["total"] >= precio_correcto
          #aceptar
          inv.accepted = true
          inv.save!
          if cliente != "distribuidor"
            client_url = Client.find_by(name: cliente).url
            #notifico de factura aceptada al cliente
            notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{client_url}invoices/#{factura_id}/accepted")
            puts notification.to_s
            pagar_factura(fact["total"], cuenta_banco, factura_id)
          end


        else
          #rechazar
          inv.rejected = true
          inv.save!
          if cliente != "distribuidor"
            client_url = Client.find_by(name: cliente).url
            #rechazo factura
            rechazo = HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_factura + "reject", json: {id: factura_id, motivo: "Su monto a pagar es menor al esperado"})
            #notifico del rechazo de factura al cliente
            if rechazo.code == 200
              notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{client_url}invoices/#{factura_id}/rejected")
              puts notification.to_s
            end
          end
        end
      end
    else
      render json:{ok: "Factura no encontrada"} , status:400
    end
  end

  def pagar_factura(monto, cuenta_cliente, factura_id)
    trx = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_banco + "trx", :json => { :monto => monto, :origen => Rails.configuration.banco_id, :destino => cuenta_cliente})
    puts trx.to_s
    if trx.code == 200
      notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{client_url}invoices/#{factura_id}/paid", json: {id_transaction: trx.parse["_id"]})
      if notification.code != 200
        puts notification.to_s
      end
    end
  end

end
