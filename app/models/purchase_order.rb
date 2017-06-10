# == Schema Information
#
# Table name: purchase_orders
#
#  id            :integer          not null, primary key
#  _id           :string
#  client        :string
#  supplier      :string
#  sku           :string
#  delivery_date :datetime
#  amount        :integer
#  delivered_qt  :integer
#  unit_price    :integer
#  channel       :string
#  status        :string
#  notes         :string
#  rejection     :string
#  anullment     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'http'
require 'digest'
class PurchaseOrder < ApplicationRecord


  def self.getPurchaseOrder(id)
    #TODO GEt the pruchase order form the server. And return a Json parse of the PurchaseORder.
    response = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{id}")
    return response
  end



  def self.receivePurchaseOrder(id)
    #TODO Mark your Purcase Order as received
    response = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{id}")
    if response.code == 200
      # Crear en BDD local

      orden = JSON.parse response.to_s
      if !PurchaseOrder.where(_id:  orden[0]["_id"]).exists?
        orden_temp = PurchaseOrder.new

        orden_temp.channel = orden[0]["canal"]
        orden_temp.amount = orden[0]["cantidad"].to_i
        orden_temp.sku = orden[0]["sku"]
        orden_temp.supplier = orden[0]["proveedor"]
        orden_temp.unit_price =  orden[0]["precioUnitario"]
        orden_temp.notes = orden[0]["notas"]
        orden_temp.delivery_date = orden[0]["fechaEntrega"]
        orden_temp.delivered_qt = orden[0]["cantidadDespachada"]
        orden_temp._id = id
        orden_temp.status = orden[0]["estado"]
        if orden_temp.save!
          return true
        end
      end
    end
    return false
  end

  def self.rejectPurchaseOrder(id,motivo)
    #TODO reject the purhcase order from the system
  end

  def self.createPurchaseOrder(channel,amount,sku,supplier,unit_price, notes, delivery_date)
    # TODO crete the purchase Order and send a Json response.
    cliente = Rails.configuration.my_id
    response =HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_oc +'crear', :json => { :cliente => cliente, :proveedor => supplier, :sku => sku, :fechaEntrega => delivery_date, :cantidad => amount, :precioUnitario => unit_price, :canal => channel })
    if response.code == 200
      # Crear en BDD local
      orden_temp = PurchaseOrder.new
      orden_temp.channel = channel
      orden_temp.amount = amount
      orden_temp.sku = sku
      orden_temp.supplier = supplier
      orden_temp.unit_price = unit_price
      orden_temp.notes = notes
      orden_temp.delivery_date=delivery_date
      orden_temp.delivered_qt = 0
      orden_temp._id = response.parse["_id"]
      orden_temp.status = response.parse["status"]
      if orden_temp.save!
        idresponse = response.parse["_id"]
        return idresponse
      end
    end

    return "error"
  end

##Método para Ftp. Checkea si existe y crea la roden en BDD. Si no existe retorna falso. Si no puede crear la orden retorna falso.
  def check_purchase_order(_id )
      #TODO chequar si existe si no ir a uscarla al sistema del profe y crearla. Retorna true si la crea o encuentra, false en caso contrario.
        response = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{_id}")
        if response.code == 200 # Si la orden de compra existe en el sistema.

            orden = JSON.parse response.to_s
            orden_temp = PurchaseOrder.new
            if !PurchaseOrder.where(_id:  orden[0]["_id"]).exists?

              orden_temp._id = orden[0]["_id"]
              orden_temp.client = orden[0]["cliente"]
              orden_temp.supplier = orden[0]["proveedor"]
              orden_temp.sku = orden[0]["sku"]
              orden_temp.delivery_date = orden[0]["fechaEntrega"]
              orden_temp.amount = orden[0]["cantidad"].to_i
              orden_temp.delivered_qt = orden[0]["cantidadDespachada"]
              orden_temp.unit_price = orden[0]["precioUnitario"]
              orden_temp.channel = orden[0]["canal"]
              orden_temp.status = orden[0]["estado"]
              orden_temp.notes = orden[0]["notas"]
              orden_temp.rejected = orden[0]["rechazo"]
              orden_temp.anullment = orden[0]["anulacion"]
              orden_temp.created_at = orden[0]["created_at"]


              if orden_temp.save!
                return true
              else
                return false
              end
            end
        end
      return false
  end

end
