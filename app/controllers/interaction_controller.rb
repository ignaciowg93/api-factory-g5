require "http"
require 'digest'

class InteractionController < ApplicationController
  before_action :get_almacenes
  # Methods for manual implementation from dashboard

  def receive
        # Receive purchase order
        # Verified body request
        # Validar que el precio sea correcto
        if !(params.has_key?(:payment_method) && params.has_key?(:id_store_reception))
            if !(params.has_key?(:payment_method))
                render json: {error: "Falta método de pago"}, status:400
            elsif !(params.has_key?(:id_store_reception))
                render json: {error: "Falta bodega de recepción"}, status:400
            end
        else
            if params[:payment_method].empty? || params[:payment_method].nil?
                render json: {error: "Falta método de pago"}, status:400
            elsif params[:id_store_reception].empty? || params[:id_store_reception].nil?
                render json: {error: "Falta bodega de recepción"}, status:400
            else

              poid = params["id"]
              response = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{poid}")
              orden = JSON.parse response.to_s

              if response.status.code != 200
                  render json: {error: "Orden de compra inexistente"}, status:404
              else
                  render json:{ok: "OC recibida exitosamente"} , status:200

                  Thread.new do
                    id = orden[0]["_id"]
                    cliente = orden[0]["cliente"]
                    proveedor = orden[0]["proveedor"]
                    sku = orden[0]["sku"]
                    fechaEntrega = orden[0]["fechaEntrega"]
                    cantidad = orden[0]["cantidad"].to_i
                    cantidadDespachada = orden[0]["cantidadDespachada"]
                    precioUnitario = orden[0]["precioUnitario"]
                    canal = orden[0]["canal"]
                    estado = orden[0]["estado"]
                    notas = orden[0]["notas"]
                    rechazo = orden[0]["rechazo"]
                    anulacion = orden[0]["anulacion"]
                    created_at = orden[0]["created_at"]
                    stock = Stock.find_by(sku: sku) # Poblar base de datos
                    prod = Product.find_by(sku: sku)
                    grupo = Client.find_by(name: cliente)
                    en_stock = get_stock_by_sku(prod)

                    if grupo == nil
                        estado = "rechazada"
                        rechazo = "cliente inválido"
                        HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_oc+"rechazar/"+poid,
                         json: {_id: poid, rechazo: rechazo})
                        return

                    # No hay stock ###y el tiempo de produccion excede la fecha de entrega
                    elsif en_stock < cantidad
                        estado = "rechazada"
                        rechazo = "Sin stock"
                        PurchaseOrder.create(_id: poid, #payment_method: " ", payment_option: " ",
                                             sku: sku, amount: cantidad,
                                             status: estado, delivery_date: fechaEntrega,
                                             unit_price: precioUnitario, rejection: rechazo)
                        HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_oc+"rechazar/"+poid,
                        json: {_id: poid, rechazo: rechazo})
                        HTTP.headers(accept: "application/json").patch(group_route(grupo) +poid + '/rejected',
                        json: {cause: rechazo})
                        return

                    else
                        # Reservar unidades
                        prod.stock_reservado += cantidad
                        prod.save
                        estado = "aceptada"
                        orden = PurchaseOrder.create(_id: poid, #payment_method: " ", payment_option: " ",
                                             sku: sku, amount: cantidad,
                                             status: estado, delivery_date: fechaEntrega,
                                             unit_price: precioUnitario, rejection: " ", delivered_qt: 0)
                        HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_oc+"recepcionar/"+poid,
                         json: {_id: poid})
                        HTTP.headers(accept: "application/json").patch(group_route(grupo) +poid + '/accepted')

                        # Despachar
                        to_despacho_and_delivery(sku, cantidad, params[:id_store_reception], poid, precioUnitario, "b2b")
                    end
                  end
              end
            end
        end
  end


  def produce

    sku = params[:sku]
    puts "sku= #{sku}"
    quantity = params[:quantity]
    product = (Product.find_by sku: sku)

    # Definir lote de produccion
    lot = product.lot
    to_produce = lot
    while to_produce / quantity < 1 do
      to_produce += lot
    end
    n_lotes = to_produce/lot



    if product.processed == 1
      puts "procesado"
      n_lotes.times do
        # Si producto procesado, verificar stock de materias primas, y mandar a despacho
        my_supplies = product.supplies
        # Pedir sku de todos los supplies
        my_supplies.each do |supply|
          # Verificar que haya stock
          stocks = get_stocks
          if supply.requierment >= stocks[supply.sku]
            remain = supply.requierment - stocks[supply.sku]
            # FIXME: Solo se produce si hay stock
            # # Abastecerse del resto
            # abastecimiento_mp(sku, supply.sku, remain, fecha, Rails.configuration.recepcion_id)
            render json: {error: "Faltan #{remain} unidades de sku #{supply.sku}"}, status: 400
            return
          end
        end
        # Mover unidades a almacen de despacho
        my_supplies.each do |supply|
          puts "1- muevo a despacho"
          move_to_despacho(supply.requierment, supply.sku)
        end
        # Producir un solo lote
        mandar_a_producir(lot,product, sku)
      end
    else
      puts "no procesado"
      # Producir todo
      mandar_a_producir(to_produce, product, sku)
    end
  end

  def mandar_a_producir(quantity, product, sku)
    puts "en mandar a producir"
    remaining = quantity
    # Producir
    # FIXME: refactoring
    # FIXME: Error
    # FIXME: thread para la solicitud
    #Ir y producir stock, máximo 5000 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.
    ### Creo que no está haciendo 5000 por ciclo. Está haciendo menos.

    #transferir $$ a fábrica
    longest_time = Time.now
    while remaining >= 0
      # request de producción
      if remaining > 5000
        to_produce = remaining
        while to_produce > 5000
          to_produce -= lot
        end
      else
        to_produce = remaining
      end
      puts "to_produce = #{to_produce}"
      #pagar producción
      data = "GET"
      #puts("antes")
      monto = to_produce * product.price.to_i
      #puts("monto= #{monto}")
      factory_account2 = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "fabrica/getCuenta")
      #puts("factory to_s: #{factory_account2.to_s}")
      factory_account = factory_account2.parse["cuentaId"]
      #puts("factory_account: #{factory_account}")
      trx1 = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_banco + "trx", :json => { :monto => monto, :origen => Rails.configuration.banco_id, :destino => factory_account })
      puts trx1.to_s
      #puts("trx1: #{aviso}")
      #Producir
      if trx1.code == 200
        data = "PUT" + sku + to_produce.to_s + trx1.parse["_id"]
        puts("ahora remaining: #{remaining}")
        puts("p_order antes")
        production_order = HTTP.auth(generate_header(data)).headers(:accept => "application/json").put(Rails.configuration.base_route_bodega + "fabrica/fabricar", :json => { :sku => sku, :cantidad => to_produce, :trxId =>  trx1.parse["_id"]})
        puts("p_order dsps")
        production_order_to_save = ProductionOrder.new
        production_order_to_save.sku = sku
        production_order_to_save.amount =  to_produce
        production_order_to_save.est_date = production_order.parse["disponible"]
        # FIXME guardar hora de entrega
        if production_order_to_save.save!
          if production_order.code == 200
            puts("en el if: #{production_order.parse}")
            # podría quizás guardar la fecha esperada de entrega, estado despachado, etc.
            # guradar orden de produccion
            if longest_time < production_order.parse["disponible"]
              longest_time = production_order.parse["disponible"]
            end
            remaining -= 5000
          elsif production_order.code == 429
            puts("en el else if")
            #esperar 1 minuto
            sleep(60)
          else
            a = production_order.to_s
            puts("error en p_order: #{a}")
          end
        end
      end
    end
  end

  # Para despachar directamente
  def despachar
    orden_id = params[:id]
    almacen_recepcion = params[:id_store_reception]
    order = ""
    loop do
      order = HTTP.headers(accept: "application/json").get("#{Rails.configuration.base_route_oc}obtener/#{orden_id}")
      break if order.code == 200
      sleep(60) if order.code == 429
      sleep(15)
    end
    order = order.parse
    to_despacho_and_delivery(order[0]["sku"], order[0]["cantidad"].to_i, almacen_recepcion, orden_id, order[0]["precioUnitario"], "b2b")
  end

  def to_despacho_and_delivery(sku, qty, almacen_recepcion, ordenId, precio, cantidad_despachada)
    # Mover unidad a despacho, hacer delivery
    # Mantener stock reservado para que no se vayan las unidades
    products = ""
    # FIXME: la cantidad despachada no se actualiza siempre en el sistema!!
    #remaining = qty - cantidad_despachada
    orden = PurchaseOrder.find_by(_id: ordenId)
    remaining = qty - orden.delivered_qt
    # Obtener producto con sku
    prod = Product.find_by(sku: sku)


    while remaining > 0 do
      @almacenes.each do |almacen|
        next if almacen["despacho"]
        limit = (remaining if remaining < 200) || 200
        data = "GET#{almacen["_id"]}#{sku}" #GETalmacenIdsku
        route = "#{Rails.configuration.base_route_bodega}stock?almacenId=#{almacen["_id"]}&sku=#{sku}&limit=#{limit}"
        loop do
          products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route)
          break if products.code == 200
          sleep(60) if products.code == 429
          sleep(15)
        end
        products.parse.each do |product|
          data = "POST#{product["_id"]}#{Rails.configuration.despacho_id}" #POSTproductoIdalmacenId
          route = "#{Rails.configuration.base_route_bodega}moveStock"
          move = ""
          loop do
            move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: Rails.configuration.despacho_id })
            break if move.code == 200
            sleep(60) if move.code == 429
            sleep(15)
          end
          # Delivery
          data = "POST#{product["_id"]}#{almacen_recepcion}"
          route = "#{Rails.configuration.base_route_bodega}moveStockBodega"
          loop do
            deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: almacen_recepcion, oc: ordenId, precio: precio})
            break if deliver.code == 200
            sleep(60) if deliver.code == 429
            sleep(15)
          end
          remaining -= 1
          # Liberar unidades reservadas
          # Aumentar en unidades despachadas
          prod.stock_reservado -= 1
          prod.save
          orden.delivered_qt += 1
          orden.save
        end
      end
    end
    # Orden de compra se cambia a finalizada en la base local
    orden.status = 'finalizada'
    orden.save
  end

  def move_to_despacho(qty, sku)
    products = ""
    remaining = qty
    while remaining > 0 do
      @almacenes.each do |almacen|
        next if almacen["despacho"]
        limit = (remaining if remaining < 200) || 200
        data = "GET#{almacen["_id"]}#{sku}" #GETalmacenIdsku
        route = "#{Rails.configuration.base_route_bodega}stock?almacenId=#{almacen["_id"]}&sku=#{sku}&limit=#{limit}"
        loop do
          products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route)
          break if products.code == 200
          sleep(60) if products.code == 429
          sleep(15)
        end
        products.parse.each do |product|
          data = "POST#{product["_id"]}#{Rails.configuration.despacho_id}" #POSTproductoIdalmacenId
          route = "#{Rails.configuration.base_route_bodega}moveStock"
          move = ""
          loop do
            move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: Rails.configuration.despacho_id })
            break if move.code == 200
            sleep(60) if move.code == 429
            sleep(15)
          end
          remaining -= 1
        end
      end
    end
  end

  # Stock de todos los sku. Se aprovecha la consulta
  def get_stocks
    stocks = Hash.new(0)
    response = ""
    @almacenes.each do |almacen|
      # No busca en despacho
      next if almacen["despacho"]
      data = "GET#{almacen["_id"]}"
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=" + almacen["_id"])
        break if response.code == 200
        sleep(60) if response.code == 429
        sleep(15)
      end
      products = JSON.parse response.to_s
      products.each do |product|
        # product["_id"] es el sku del producto
        # FIXME: restar unidades reservadas
        stocks[product["_id"]] += product["total"]
      end
    end
     # Descontar stock reservado, de todos los sku (productos y supplies)
    productos_db = Product.all
    supplies_db = Supply.all

    productos_db.each do |producto|
      stocks[producto.sku] -= producto.stock_reservado
    end
    supplies_db.each do |supply|
      stocks[supply.sku] -= supply.stock_reservado
    end
    stocks
  end

  def get_stock_by_sku(prod) # FIXME: producto en vez de sku
    sku = prod.sku
    stock = 0
    response = ""
    @almacenes.each do |almacen|
      # No busca en despacho
      next if almacen["despacho"]
      data = "GET#{almacen["_id"]}"
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=" + almacen["_id"])
        break if response.code == 200
        sleep(60) if response.code == 429
        sleep(15)
      end
      products = JSON.parse response.to_s
      if !products.empty?
        products.each do |product|
          # Sku viene en id de producto
            if product["_id"] == sku
                stock += product["total"]
            end
        end
      end
     end
    stock - prod.stock_reservado > 0 ? (stock - prod.stock_reservado) : 0
  end

  private

  def get_almacenes
    # Ordenar intermedio, recepcion, pulmon (?)
    # FIXME: guardar los id directamente
    data = "GET"
    response = ""
    loop do
      response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
      break if response.code == 200
      sleep(60) if response.code == 429
      sleep(15)
    end
    @almacenes = JSON.parse response.to_s
  end

  def generate_header(data)
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
    signature = Base64.encode64(hmac).chomp
    auth_header = "INTEGRACION grupo5:" + signature
    auth_header
  end

  def group_route(client)
    gnumber = client.gnumber
    if gnumber == "2"
      'http://integra17-' + gnumber + '.ing.puc.cl/purchase_orders/'
    elsif gnumber == "7"
      'http://integra17-' + gnumber + '.ing.puc.cl/purchase_orders/'
    else
      'http://integra17-' + gnumber + '.ing.puc.cl/purchase_orders/'
    end
  end


end
