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
    # TODO: GEt the pruchase order form the server. And return a Json parse of the PurchaseORder.
    response = HTTP.headers(accept: 'application/json').get("#{Rails.configuration.base_route_oc}obtener/#{id}")
    response
  end

  def self.rejectPurchaseOrder(poid, motivo)
    # TODO: reject the purhcase order from the system
    aviso_sistema = HTTP.headers(accept: 'application/json').post(Rails.configuration.base_route_oc + 'rechazar/' + poid,
                                                                  json: { _id: poid, rechazo: motivo })
    if (aviso_sistema == 200)
      return true
    else
      return false
    end
  end

  def self.acceptPurchaseOrder(poid)
    # TODO: reject the purhcase order from the system
    aviso_sistema = HTTP.headers(accept: 'application/json').post(Rails.configuration.base_route_oc + 'recepcionar/' + poid,
                                                                  json: { _id: poid })
    if (aviso_sistema == 200)
      return true
    else
      return false
    end
  end

  # Se crea PO si es que es valida en el sistema, y no esta creada en db
  # true si existe
  def check_purchase_order(_id)
    response = HTTP.headers(accept: 'application/json').get("#{Rails.configuration.base_route_oc}obtener/#{_id}")
    return false unless response.code == 200 && !response.parse.empty?

    orden = JSON.parse response.to_s
    return true if PurchaseOrder.where(_id: orden[0]['_id']).exists?

    # Create if not in db
    assign_attributes(
      _id: orden[0]['_id'],
      client: orden[0]['cliente'],
      supplier: orden[0]['proveedor'],
      sku: orden[0]['sku'],
      delivery_date: orden[0]['fechaEntrega'],
      amount: orden[0]['cantidad'].to_i,
      delivered_qt: orden[0]['cantidadDespachada'],
      unit_price: orden[0]['precioUnitario'],
      channel: orden[0]['canal'],
      status: orden[0]['estado'],
      notes: orden[0]['notas'],
      rejection: orden[0]['rechazo'],
      anullment: orden[0]['anulacion'],
      created_at: orden[0]['created_at']
    )

    return true if save!
  end
  false
end
