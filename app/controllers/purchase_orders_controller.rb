require 'http'
require 'digest'
require 'net/ftp'
require 'net/ssh'
require 'net/sftp'

class PurchaseOrdersController < ApplicationController
  def new
    @purchase_order = PurchaseOrder.new
  end

  def generate_PO
    # PO from us to others B2B
    proveedor = Client.find_by(gnumber: params[:grupo])
    cotizar = PurchaseOrder.cotizar(proveedor, params[:sku])
    # Si no se puede leer de la api, se asume que se reviso manualmente
    unless cotizar.nil? || cotizar[:stock] >= params[:cantidad].to_i
      return render(json: { error: "No disponen de stock suficiente. Stock: #{cotizar[:stock]}" },
             status: 400)
    end

    response = HTTP.headers(accept: 'application/json').put(
      "#{Rails.configuration.base_route_oc}crear",
      json: {
        cliente: Rails.configuration.my_id,
        proveedor: proveedor.name,
        sku: params[:sku],
        fechaEntrega: params[:fechaEntrega] ||
        (Time.zone.now + 3.day).to_f * 1000,
        cantidad: params[:cantidad],
        precioUnitario: params[:precioUnitario] || cotizar[:precio],
        canal: 'b2b',
        notas: params[:notas] || 'vacio'
      }
    )
    unless response.code == 200
      return render(json: { error: 'No se pudo ingresar la orden en el sistema' },
             status: 400)
    end

    orden = JSON.parse(response.body)
    # Save to db
    PurchaseOrder.create!(
      _id: orden['_id'],
      client: orden['cliente'],
      supplier: orden['proveedor'],
      sku: orden['sku'],
      delivery_date: orden['fechaEntrega'],
      amount: orden['cantidad'].to_i,
      delivered_qt: orden['cantidadDespachada'],
      unit_price: orden['precioUnitario'],
      channel: orden['canal'],
      notes: orden['notas'],
      rejection: orden['rechazo'],
      anullment: orden['anulacion'],
      created_at: orden['created_at'],
      status: orden['estado']
    )

    # Notificar
    notification =
      HTTP.headers(
        accept: 'application/json',
        'X-ACCESS-TOKEN' => Rails.configuration.my_id.to_s
      ).put(
        "#{Client.find_by(gnumber: params[:grupo]).url}purchase_orders/#{orden['_id']}",
        json: {
          payment_method: params[:payment_method] || 'contra_factura',
          id_store_reception: Rails.configuration.recepcion_id
        }
      )

    if notification.code == 200
      render(json: { success: 'Orden ha sido recibida por el destinatario',
                     _id: orden['_id'] },
             status: 200)
    else
      render(json: { error: 'Request al proveedor no fue exitosa',
                     response: JSON.parse(notification.body),
                     _id: orden['_id'] },
             status: 200)
    end
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
        puts "aca"
        Invoice.create_invoice(poid, false)
        Warehouse.to_despacho_and_delivery(poid)
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
      render(json: { success: 'Orden recibida exitosamente. Se procederá a despacho al momento de aceptar y notificar factura por enviar' }, status: 200)

      # Thread.new do #TODO si se quiere auto-atencion en algunos casos (falta rellenar order.auto_responder?)
      #   order = PurchaseOrder.find_by(_id: params[:id])
      #   return unless order && order.can_be_served? && order.auto_responder?
      #
      #   PurchaseOrder.acceptPurchaseOrder(params[:id])
      #   client = Client.find_by(name: order.client)
      #   grupo = client.gnumber
      #   HTTP.headers(accept: 'application/json').patch(group_route(grupo) + params[:id] + '/accepted')
      #
      #   factura_id = Invoice.create_invoice(params[:id], false)
      #   # Notificar envio factura
      #   if factura_id
      #     HTTP.headers(:accept => 'application/json', 'X-ACCESS-TOKEN' => Rails.configuration.my_id.to_s).put("#{client.url}invoices/#{factura_id}", json: { bank_account: Rails.configuration.banco_id })
      #   end
      # end
    else
      render(json: { error: 'Orden de compra inválida' }, status: 400)
    end
  end

  def processPO_b2b
    # FIXME: No se esta rechazando en ningun caso por ahora
    order = PurchaseOrder.find_by(_id: params[:id])
    return unless order && order.can_be_served?

    PurchaseOrder.acceptPurchaseOrder(params[:id])
    client = Client.find_by(name: order.client)
    grupo = client.gnumber
    HTTP.headers(accept: 'application/json').patch(group_route(grupo) + params[:id] + '/accepted')

    factura_id = Invoice.create_invoice(params[:id], false)
    # Notificar envio factura
    if factura_id
      HTTP.headers(:accept => 'application/json', 'X-ACCESS-TOKEN' => Rails.configuration.my_id.to_s).put("#{client.url}invoices/#{factura_id}", json: { bank_account: Rails.configuration.banco_id })
    end
    # Se despacha al aceptar la factura
  end

  ## BUYING

  def accepted
    #FIXME chequear que no esten vacios
    order = PurchaseOrder.find_by(_id: params[:id])
    # Retrieve from the system
    oc = HTTP.headers(accept: 'application/json').get(Rails.configuration.base_route_oc + 'obtener/' + params[:id])
    unless oc.code == 200
      render(json: { error: 'Orden de compra no encontrada' }, status: 404) &&
        return
    end
    puts oc.parse
    unless oc.parse[0]['estado'] == 'aceptada'
      puts "aca adentro"
      render(json: { error: 'Orden de compra no se encuentra aceptada en el sistema' }, status: 400) &&
        return
    end

    order.update(status: 'aceptada')
    render json: { ok: 'Resolución recibida exitosamente' }, status: 200
  end

  def rejected
    return render({
        json: { error: "Por favor entregar razón de rechazo 'cause:'" },
          status: 400
    }) if params[:cause].blank?

    @purchase_order = PurchaseOrder.find_by(_id: params[:id])
    @purchase_order.update(status: "rechazada")
    # Rechazar en el sistema, para asegurarse
    notificacion_sistema = HTTP.headers(accept: 'application/json').post(Rails.configuration.base_route_oc + 'rechazar/' + poid,
                                                                  json: { _id: params[:id], rechazo: params[:cause] })
    if notificacion_sistema.code == 200
      render json: { ok: 'Resolución recibida exitosamente' }, status: 200
    else
      render json: { error: 'Favor rechazar en el sistema' }, status: 404
    end
  end

  def create(sku)
    ## Tenemos que generarla nosotros , por lo tanto los parametros entrar desde nuestra BDD
  end

  def purchase_order_params
    params.permit(:purchase_order, :id, :payment_method, :payment_option, :rejection, :poid, :direccion)
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
