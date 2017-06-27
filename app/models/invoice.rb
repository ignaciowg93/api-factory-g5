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
#  belongs_to :purchase_order, optional: true

  validates :invoiceid, uniqueness: true


  def self.por_pagar(factura_id)
    factura = ""
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id)
      if factura.code == 200
        break
      end
    end
    puts "factura: #{factura.to_s}"
    if factura.code == 200 && !factura.parse.empty?
      pagado = factura.parse[0]["estado"]
      if pagado != "pendiente"
        return false
      else
        return true
      end
    end
    return false
  end

  def self.check_accepted(factura_id)
    factura = ""
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id)
      if factura.code == 200
        break
      end
    end
    puts "factura: #{factura.to_s}"
    if factura.code == 200 && !factura.parse.empty?
      pagado = factura.parse[0]["estado"]
      if pagado != "rechazada" && pagado != "anulada"
        return true
      else
        return false
      end
    end
    return false
  end

  def self.imprimir()
    return "en invoice"
  end

  def self.create_invoice(po_id, boleta)
    # Crea la factura y retorna el objeto JSON.
    #factura = HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_factura, json: {oc: po_id})
    3.times do
      factura = HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_factura, json: {oc: po_id})
      if factura.code == 200 && !factura.parse.empty?
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
          return fact_temp
        end
      end
      sleep(20)
    end
    return false
  end

  def self.rec_invoice(factura_id)
    factura = ""
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id, json: {id: factura_id})
      if factura.code == 200
        if factura.parse.empty?
          return false
        end
        break
      end
      sleep(20)
    end
    if factura.code == 200
      return factura
    else
      return false
    end
  end

  def self.ya_pagada(factura_id)
    factura = ""
    3.times do
      factura = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_factura + factura_id)
      if factura.code == 200
        break
      end
    end
    if factura.code == 200
      oc_id = factura.parse[0]["oc"]
      if Invoice.where(po_idtemp: oc_id, paid: true).count > 0
        return true
      else
        return false
      end
    end
    return true

  end

  def self.atender_factura(factura, factura_id, cuenta_banco)
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

    proveedor = factura.parse[0]["proveedor"]
    if factura.parse[0]["total"] >= precio_correcto
      #aceptar (en el sistema no se puede)
      inv.accepted = true
      inv.save!

      proveedor_url = Client.find_by(name: proveedor).url
      #notifico de factura aceptada al proveedor
      notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{proveedor_url}invoices/#{factura_id}/accepted")
      #notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("http://localhost:3000/invoices/#{factura_id}/accepted")
      pago = Invoice.pagar_factura(fact["total"], cuenta_banco, factura_id, proveedor_url)
      puts "banco responde #{pago}"
      if pago.code == 200
        inv.paid = true
        inv.save!
        return pago
      end
      return "no se pudo"


    else
      #rechazar
      inv.rejected = true
      inv.save!

      proveedor_url = Client.find_by(name: proveedor).url
      #rechazo factura
      rechazo = HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_factura + "reject", json: {id: factura_id, motivo: "Su monto a pagar es menor al esperado"})
      #notifico del rechazo de factura al cliente
      if rechazo.code == 200
        notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{proveedor_url}invoices/#{factura_id}/rejected")
        #notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("http://localhost:3000/invoices/#{factura_id}/rejected")
        return notification.to_s
      end
    end
  end


  def self.pagar_factura(monto, cuenta_cliente, factura_id, proveedor_url)
    trx = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_banco + "trx", :json => { :monto => monto, :origen => Rails.configuration.banco_id, :destino => cuenta_cliente})
    #return trx.code
    if trx.code == 200
      notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{proveedor_url}invoices/#{factura_id}/paid", json: {id_transaction: trx.parse["_id"]})
    end
    return trx
  end

end
