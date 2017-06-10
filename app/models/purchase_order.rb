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
base_route = "https://integracion-2017-dev.herokuapp.com/oc/"

  def self.getPurchaseOrder(id)
    #TODO GEt the pruchase order form the server. And return a Json parse of the PurchaseORder.
    orden = orden = HTTP.get(base_route+"obtener/"+id)
    return orden
  end

  def self.receivePurchaseOrder(id)
    #TODO Mark your Purcase Order as received
  end

  def self.rejectPurchaseOrder(poid,motivo)
    #TODO reject the purhcase order from the system
    aviso_sistema = HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_oc+"rechazar/"+poid,
    json: {_id: poid, rechazo: motivo})
    if(aviso_sistema == 200)
      return true
    else
      return false
    end
  end

  def self.acceptPurchaseOrder(poid,motivo)
    #TODO reject the purhcase order from the system
    aviso_sistema = HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_oc+"recepcionar/"+poid,
    json: {_id: poid})
    if(aviso_sistema == 200)
      return true
    else
      return false
    end
  end

  def self.createPurchaseOrder(channel,amount,sku,supplier,unit_price, notes, client, delivery_date)
    # TODO crete the purchase Order and send a Json response.
  end


  def check_purchase_order(_id )
      #TODO chequar si existe si no ir a uscarla al sistema del profe y crearla. Retorna true si la crea o encuentra, false en caso contrario.
  end


end
