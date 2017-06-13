require 'http'
require 'digest'
require 'net/ftp'
require 'net/ssh'
require 'net/sftp'

class PurchaseOrdersController < ApplicationController
  def new
    @purchase_order = PurchaseOrder.new
  end

  def receive_ftp
    # Automatically serve all requests, in order
    Net::SFTP.start(Rails.configuration.host, Rails.configuration.ftp_user,
                    password: Rails.configuration.ftp_pass) do |sftp|
      sftp.dir.foreach('/pedidos') do |entry|
        next unless entry.file?
        nombre_split = entry.longname.split
        nombre = nombre_split[8]

        data = sftp.download!('/pedidos/' + entry.name)
        doc = Nokogiri::XML(data)
        thing = doc.at_xpath('order')
        poid = thing.at_xpath('//id').content

        # Load PO, or create
        order = PurchaseOrder.find_by(_id: poid) ||
                PurchaseOrder.check_purchase_order(poid, 'distribuidor') &&
                PurchaseOrder.find_by(_id: poid)

        next unless order && order.can_be_served?
        # TODO: factura
        Warehouse.to_despacho_and_delivery(order.sku, order.amount,
                                           order.direccion,
                                           poid, order.unit_price, 'ftp')
      end
    end
  end

  # B2B Check a PO that was created for us.
  def receive_b2b
    payment_method_presence = params.key?(:payment_method) &&
                              !params[:payment_method].nil? &&
                              !params[:payment_method].empty?

    id_store_presence = params.key?(:id_store_reception) &&
                        !params[:id_store_reception].nil? &&
                        !params[:id_store_reception].empty?

    unless payment_method_presence
      render(json: { error: 'Falta método de pago' }, status: 400) &&
        return
    end
    unless id_store_presence
      render(json: { error: 'Falta bodega de recepción' }, status: 400) &&
        return
    end

    if PurchaseOrder.exists?(_id: params[:id])
      render(json: { error: 'Orden ya recepcionada' }, status: 400)
    elsif PurchaseOrder.check_purchase_order(params[:id],
                                             params[:id_store_reception])
      render(json: { error: 'Orden recibida exitosamente. Se procederá a despacho al momento de aceptar y notificar factura enviada' }, status: 200)
    else
      grupo = Client.find_by(name: order.client).gnumber
      motivo = 'Orden de compra inexistente'
      HTTP.headers(accept: 'application/json').patch(group_route(grupo) + params[:id] + '/rejected',
                                                     json: { cause: motivo })
      render(json: { error: motivo }, status: 400)
    end
  end

  def processPO_b2b

    order = PurchaseOrder.find_by(_id: params[:id])
    return unless order && order.can_be_served?

    PurchaseOrder.acceptPurchaseOrder(params[:id])
    grupo = Client.find_by(name: order.client).gnumber
    HTTP.headers(accept: 'application/json').patch(group_route(grupo) + params[:id] + '/accepted')

    # Procesar PO
    Invoice.create_invoice(params[:id], false)
    # Notificar envio factura
    sent_notification = HTTP.headers(:accept => 'application/json', 'X-ACCESS-TOKEN' => Rails.configuration.my_id.to_s).put("#{client_url}invoices/#{factura_id}", json: { bank_account: Rails.configuration.banco_id })
    # TODO: To_despacho and delivery desde /invoices/:id/accepted
  end

  ## BUYING

  def accepted
    @purchase_order = PurchaseOrder.find_by(_id: params[:id])
    if @purchase_order.status == 'creada'
      oc = HTTP.headers(accept: 'application/json').get('https://integracion-2017-dev.herokuapp.com/oc/obtener/' + params[:id])
      if oc.code == 200
        orden_compra = oc.parse[0]
        if orden_compra['estado'] == 'aceptada'
          puts('bbb')
          if @purchase_order
            puts('ccc')
            @purchase_order.status = 'aceptada'
            if @purchase_order.save!
              render json: { ok: 'Resolución recibida exitosamente' }, status: 200
            end
          end
        else
          puts('a versh')
          render json: { error: 'Orden de compra No se encuentra aceptada en el sistema' }, status: 400
        end
      else
        render json: { error: 'Orden de compra no encontrada' }, status: 404
      end
    else
      render json: { error: 'Orden de Compra ya resuelta' }, status: 403
      # The provider rejects a PO created by us. Check its existance.
    end
  end

  def rejected
    if params.key?(:cause)
      @causa = params[:cause]
      if @causa == ''
        render json: { error: 'Debe entregar una razón de rechazo' }, status: 400
      else
        if @causa.nil?
          render json: { error: 'Debe entregar una causa distinta de nula' }, status: 400
        end
      end
    else
      render json: { error: 'Formato de body incorrecto' }, status: 400
    end
    @purchase_order = PurchaseOrder.find_by(_id: params[:id])
    if @purchase_order.status == 'creada'
      oc = HTTP.headers(accept: 'application/json').get('https://integracion-2017-dev.herokuapp.com/oc/obtener/' + params[:id])
      if oc.code == 200
        orden_compra = oc.parse
        if orden_compra['estado'] == 'rechazada'
          if @purchase_order
            @purchase_order.status = 'rechazada'
            if @purchase_order.save!
              render json: { ok: 'Resolución recibida exitosamente' }, status: 200
            end
          end
        else
          render json: { error: 'ORden de compra No se encuentra aceptada en el sistema' }, status: 400
        end
      else
        render json: { error: 'Orden de compra no encontrada' }, status: 404
      end
    else
      render json: { error: 'Orden de Compra ya resuelta' }, status: 403
      # The provider rejects a PO created by us. Check its existance.
    end
  end

  def create(sku)
    ## Tenemos que generarla nosotros , por lo tanto los parametros entrar desde nuestra BDD
  end

  def purchase_order_params
    params.permit(:purchase_order, :id, :payment_method, :payment_option, :rejection, :poid)
  end

  def set_purchase_order
    @purchase_order = PurchaseOrder.find_by(poid: params[:id])
  end

  def group_route(gnumber)
    'http://integra17-' + gnumber + '.ing.puc.cl/purchase_orders/'
  end

  # TODO
  # When a Oc is creaed we have to check its existance in the OC server. If not return a 404.

  # TODOS2
  # Crear orden de compra, basado en el Cliente recibido por ApplicationController.Máximo 5000 por orden de compra.
  # Decidir loop de ordenes de compra. Ver errores de rechazos con la ordenes de compra.
  # Crear orden de compra ( Sistem Orden de compra). // Crear Orden De Compra
  # Mandar orden de compra al cliente (B2B). //Enviar Orden De Compra
  # Recibir apruebo o rechazo de la orden  //
  # Frente a rechazo mapear los proveedores para budcar siguiente posible proveedor Y volver a tratar.
  # Una vez creada y aceptada ,Devolverte a API, con el id de OC.
  # Desde la APi de marca como despachada
end
