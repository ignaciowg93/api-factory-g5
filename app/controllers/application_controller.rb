require "http"
require 'digest'

$secret = "W1gCjv8gpoE4JnR" # desarrollo
class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_exception
    rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique_exception
    rescue_from ActiveRecord::RecordInvalid,with: :record_invalid_exception
    rescue_from ActionController::RoutingError, with: :route_exception


###Error Management
    def record_not_found_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "No se ha encotrado el recurso solicitado"}, status: :not_found
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: :not_found
        end
    end

    def record_not_unique_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "Ha presentado un error. La entidad creada entra en conflicto con otra alojada en la base de datos. Solicitud DENEGADA"}, status: 403
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 403
        end
    end

    def record_invalid_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "El recurso es inválido."}, status: 422
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 422
        end
    end

    def route_exception(exception)
         logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "Ruta inválida!"}, status: 500
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 500
        end
    end

     unless Rails.application.config.consider_all_requests_local
        rescue_from ActionController::RoutingError, with: -> { render_404  }
     end

    def render_404
        respond_to do |format|
        format.json { render json: {error: "Ruta no encontrada!"}, status: 404 }
        format.all { render nothing: true, status: 404 }
        end
    end

    #### Métodos


    # Cotizar productos. en este sprint es solo ver el stock.

    #retornar una lista con id_seller, precio unitarios, tiempo, y stock
    def quote_a_price(sku_prod, sku_insumo, cant) #sku_insumo
      # Hacer un for de búsqueda, por lo productos.
      supplier_list = (Product.find_by sku: sku_prod).supplies.where(:sku => sku_insumo)
      #current_min_price = "0" # nosotros tenemos en string, pero debiera ser INT
      sorted_suppliers = Array.new
      #iterar sobre los distintos vendedores
      supplier_list.each do |supplier|
        #seller = supplier.seller
        seller = (Client.find_by gnumber: supplier.seller)
        #route = 'http://integra17-' + seller + '.ing.puc.cl/products'
        route = seller.url
        @response = HTTP.get(route)
        if @response.code == 200
          #VER POR CADA GRUPO
          products_list = @response.parse
          # obtengo la lista de productos del seller y cotizo
          products_list.each do |prod|
            if prod["sku"] == sku_insumo
              sorted_suppliers.push([seller.name, prod["price"], supplier.time, prod["stock"]])
            end
          end
        end
      end
      sorted_suppliers.sort!{|a,b| a[2] <=> b[2]}
      return sorted_suppliers
    end
      #Después de aceptada la OC,


      #Mandar al proveedor el Id del alamcen a recepcionar los productos de la OC asociada.
      # -> ALGUNOS LO MANDAN EN EL MENSAJE DE OC EMITIDA

      #Esperar notificación de despacho desde proveedor.

    def abastecimiento_mp(sku_prod, sku_insumo, cant_mp, fecha_max, alm_recep_id)
      oc_this_time = Array.new
      # Cotizar
      sellers = quote_a_price(sku_prod, sku_insumo, cant_mp)
      # mandar OC hasta cubrir cant_mp confirmada
      sellers.each do |seller|
        oc = HTTP.headers(:accept => "application/json").put('https://integracion-2017-dev.herokuapp.com/oc/crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => seller[0], :sku => sku_insumo, :fechaEntrega => fecha_max, :cantidad => seller[3], :precioUnitario => seller[1], :canal => "b2b" })
        if oc.code == 200
          # agrego entrada (nueva OC) en la tabla y notifico
          seller_addr =  (Client.find_by name: seller[0]).url + "purchase_orders/" + oc.parse["_id"] # ruta debiera sacarse de una base de datos
          notification = HTTP.headers(:accept => "application/json").put(seller_addr, :json => { :payment_method => "contra_factura", :id_store_reception  => alm_recep_id})
          PurchaseOrder.create(_id: oc.parse["_id"], client: oc.parse["cliente"], supplier: oc.parse["proveedor"], sku: oc.parse["sku"], delivery_date: oc.parse["fechaEntrega"], amount: oc.parse["cantidad"], delivered_qt: oc.parse["cantidadDespachada"], unit_price: oc.parse["precioUnitario"], channel: oc.parse["canal"], status: oc.parse["estado"])
          # esperar apruebo o rechazo
          while (PurchaseOrder.find_by _id: oc.parse["_id"]).status == "creada"
          end
          if (PurchaseOrder.find_by _id: oc.parse["_id"]).status == "aceptada"
            # fue aceptada
            oc_this_time.push(oc.parse["_id"])
            cant_mp -= seller[3]
          end
        end
        if cant_mp <= 0
          break
        end
      end
      while cant_mp > 0
        sellers.each do |seller|
          oc = HTTP.headers(:accept => "application/json").put('https://integracion-2017-dev.herokuapp.com/oc/crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => seller[0], :sku => sku_insumo, :fechaEntrega => fecha_max, :cantidad => cant_mp, :precioUnitario => seller[1], :canal => "b2b" })
          if oc.code == 200
            # agrgo entrada en la tabla (inicializada en id ) y notifico
            seller_addr = (Client.find_by name: seller[0]).url + "purchase_orders/" + oc.parse["_id"] # ruta debiera sacarse de una base de datos
            notification = HTTP.headers(:accept => "application/json").put(seller_addr, :json => { :payment_method => "contra_factura", :id_store_reception  => alm_recep_id})
            PurchaseOrder.create(_id: oc.parse["_id"], client: oc.parse["cliente"], supplier: oc.parse["proveedor"], sku: oc.parse["sku"], delivery_date: oc.parse["fechaEntrega"], amount: oc.parse["cantidad"], delivered_qt: oc.parse["cantidadDespachada"], unit_price: oc.parse["precioUnitario"], channel: oc.parse["canal"], status: oc.parse["estado"])
            # esperar apruebo o rechazo
            while (PurchaseOrder.find_by _id: oc.parse["_id"]).status == "creada"
            end
            if (PurchaseOrder.find_by _id: oc.parse["_id"]).status == "aceptada"
              # fue aceptada
              cant_mp -= cant_mp
            end
          end
          if cant_mp <= 0
            break
          end
        end
      end
      # retornar la lista de OCs para después verificar los despachos
      return oc_this_time
    end

    def produce_and_supplying(sku, qty, fecha_max) #producción y abastecimiento

      prdt = (Product.find_by sku: sku)
      if prdt.processed == 1
        #preparación para producir
        my_supplies_r = prdt.supplies
        current_supply_sku = ""
        my_supplies = Array.new
        my_supplies_r.each do |supply|
          if current_supply_sku != supply.sku
            #agregar al arreglo
            my_supplies.push([supply.sku, supply.requierment])

            current_supply_sku = supply.sku
          end
        end
        secret = "W1gCjv8gpoE4JnR" # desarrollo
        bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega" # desarrollo
        #Mandar a la bodega. Get sku de stock.
        data = "GET"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        worked_st = 0
        # pedimos el arreglo de almacenes
        while worked_st == 0
          almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/almacenes")
          if almacenes.code == 200
            worked_st = 1 # (no es necesario intentarlo de nuevo)
            #armo lista ordenada de almacenes
            sorted_almacenes = Array.new
            almacenes.parse.each do |almacen|
              if almacen["despacho"] == false && almacen["recepcion"] == false && almacen["pulmon"] == false # es almacen intermedio
                sorted_almacenes.push([almacen["_id"], 1])
              elsif almacen["despacho"] == false && almacen["recepcion"] == true # es recepción
                sorted_almacenes.push([almacen["_id"], 2])
                @almacen_recep_id = almacen["_id"]
              elsif almacen["despacho"] == false && almacen["recepcion"] == false # es pulmón
                sorted_almacenes.push([almacen["_id"], 3])
              else # es despacho
                sorted_almacenes.push([almacen["_id"], 4])
              end
            end
            sorted_almacenes.sort!{|a,b| a[1] <=> b[1]}
            sorted_almacenes.each do |s_almacen|
              #busco en cada almacen
              data = "GET" + s_almacen[0]
              hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
              signature = Base64.encode64(hmac).chomp
              auth_header = "INTEGRACION grupo5:" + signature
              route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId=" + s_almacen[0]
              products_array = HTTP.auth(auth_header).headers(:accept => "application/json").get(route_to_get)
              if products_array.code == 200
                # comparo con lo que necesito
                products_array.parse.each do |product|
                  my_supplies.each do |supply|
                    if supply[1] > 0 # si todavía no he alcanzado el total necesario
                      if supply[0] == product["_id"]
                        #mover a despacho (muevo directo)
                        data = "GET" + s_almacen[0] + supply[0]
                        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                        signature = Base64.encode64(hmac).chomp
                        auth_header = "INTEGRACION grupo5:" + signature
                        route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + s_almacen[0] + "&sku=" + supply[0] + "&limit=200"
                        quedan = product["total"]
                        while quedan > 0
                          prod_ids = HTTP.auth(auth_header).headers(:accept => "application/json").get(route_to_get)
                          #mover a ID DESPACHO y restarle a quedan
                          prod_ids.each do |prod|
                            data = "POST" + prod["_id"] + sorted_almacenes.last[0]
                            hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                            signature = Base64.encode64(hmac).chomp
                            auth_header = "INTEGRACION grupo5:" + signature
                            route_to_post = "https://integracion-2017-dev.herokuapp.com/bodega/moveStock"
                            move = HTTP.auth(auth_header).headers(:accept => "application/json").post(route_to_post, :json => { :productoId => prod["_id"], :almacenId => sorted_almacenes.last[0] })
                            if move.code = 200
                              quedan -= 1
                            end
                          end
                        end
                        supply[1] -= product["total"] # dcto. de los restantes (me paso en la resta quizás)
                      end
                    end
                  end
                end
              end
            end
          elsif almacenes.code == 429
            #esperar 1 minuto
            sleep(60)
          end
        end

        #Verificar stock mínimo de producción.
        my_supplies.each do |supply|
          if supply[1] > 0 # no tengo todo
            #Llamar al abastecimiento de MP.(Block anterior)
            oc_list = abastecimiento_mp(sku, supply[0], supply[1], fecha_max, @almacen_recep_id)
            oc_list.each do |oc|
              # la idea es que me notifiquen que llegó, pero por ahora debiera ser un sleep del tiempo nomás
              sleep((oc["fechaEntrega"] - (Time.now.to_f * 1000))/1000 + 1800)
              #while (Invoice_reg.find_by oc_id: oc).delivered == 0
              #end
              #mover a despacho(buscar en recepcion o pulmón)
              sorted_almacenes.each do |s_almacen|
                #busco en cada almacen
                if s_almacen[1] == 2 || s_almacen[1] == 3 #solo en recepción y pulmón
                  data = "GET" + s_almacen[0]
                  hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                  signature = Base64.encode64(hmac).chomp
                  auth_header = "INTEGRACION grupo5:" + signature
                  route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId=" + s_almacen[0]
                  worked_st2 = 0
                  while worked_st2 == 0
                    products_array = HTTP.auth(auth_header).headers(:accept => "application/json").get(route_to_get)
                    if products_array.code == 200
                      worked_st2 = 1
                      # comparo con lo que necesito
                      products_array.parse.each do |product|
                        my_supplies.each do |supply|
                          if supply[1] > 0 # si todavía no he alcanzado el total necesario
                            if supply[0] == product["_id"]
                              #mover a despacho (muevo directo)
                              data = "GET" + s_almacen[0] + supply[0]
                              hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                              signature = Base64.encode64(hmac).chomp
                              auth_header = "INTEGRACION grupo5:" + signature
                              route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + s_almacen[0] + "&sku=" + supply[0] + "&limit=200"
                              quedan = product["total"]
                              while quedan > 0
                                prod_ids = HTTP.auth(auth_header).headers(:accept => "application/json").get(route_to_get)
                                #mover a ID DESPACHO y restarle a quedan
                                prod_ids.each do |prod|
                                  data = "POST" + prod["_id"] + sorted_almacenes.last[0]
                                  hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                                  signature = Base64.encode64(hmac).chomp
                                  auth_header = "INTEGRACION grupo5:" + signature
                                  route_to_post = "https://integracion-2017-dev.herokuapp.com/bodega/moveStock"
                                  move = HTTP.auth(auth_header).headers(:accept => "application/json").post(route_to_post, :json => { :productoId => prod["_id"], :almacenId => sorted_almacenes.last[0] })
                                  if move.code = 200
                                    quedan -= 1
                                  end
                                end
                              end
                              supply[1] -= product["total"] # dcto. de los restantes (me paso en la resta quizás)
                            end
                          end
                        end
                      end
                    elsif products_array.code == 429
                      #esperar 1 minuto
                      sleep(60)
                    end
                  end
                end
              end
              ##hasta aquí pegué
            end
          end
        end
        # fin preparación para producir
      end
      #Ir y producir stock, máximo 5000 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.

      lot = (Product.find_by sku: sku).lot
      if qty <= lot
        ramaining = lot
      else
        remaining = lot * 2
        while remaining < qty
          remaining += lot
        end
      end

      #transferir $$ a fábrica
      longest_time = 0
      while remaining >= 0
        # autenticación
        data = "PUT" + sku + remaining.to_s
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        # request de producción
        if remaining > 5000
          to_produce = 5000
        else
          to_produce = remaining
        end
        production_order = HTTP.auth(auth_header).headers(:accept => "application/json").put(bodega_sist + "fabrica/fabricarSinPago", :json => { :sku => sku, :cantidad => to_produce })
        if production_order.code == 200
          # podría quizás guardar la fecha esperada de entrega, estado despachado, etc.
          if longest_time < production_order.parse["disponible"]
            longest_time = production_order.parse["disponible"]
          end
          remaining -= 5000
        elsif production_order.code == 429
          #esperar 1 minuto
          sleep(60)
        end
      end
      move_to_despacho(qty, sku)

      #retorno fecha en que todo lo fabricado debería llegar
      return longest_time + (60000 * 30)
    end


        def move_to_despacho(qty, sku)
          # Almacen recepcion 590baa76d6b4ec00049028b1
          # Almacen pulmon 590baa76d6b4ec00049029dc
          # Almacen despacho "590baa76d6b4ec00049028b2"
          almacen_recepcion = "590baa76d6b4ec00049028b1"
          almacen_pulmon = "590baa76d6b4ec00049029dc"
          almacen_despacho = "590baa76d6b4ec00049028b2"
          remain = qty
          search_pulmon = false
          while remain > 0 do
            # Buscar en recepcion
            if !search_pulmon
              data = "GET" + almacen_recepcion + sku #GETalmacenIdsku
              hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
              signature = Base64.encode64(hmac).chomp
              auth_header = "INTEGRACION grupo5:" + signature
              url = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + almacen_recepcion + "&sku=" + sku
              products = HTTP.auth(auth_header).headers(:accept => "application/json").get(url)
              remain -= products.parse.length
              search_pulmon = true if products.parse.empty?
            else
              # Buscar en pulmon
              data = "GET" + almacen_pulmon + sku #GETalmacenIdsku
              hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
              signature = Base64.encode64(hmac).chomp
              auth_header = "INTEGRACION grupo5:" + signature
              url = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + almacen_pulmon + "&sku=" + sku
              products = HTTP.auth(auth_header).headers(:accept => "application/json").get(url)
              remain -= products.parse.length
            end

            products.parse.each do |product|
              data = "POST" + product["_id"] + almacen_despacho #POSTproductoIdalmacenId
              hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
              signature = Base64.encode64(hmac).chomp
              auth_header = "INTEGRACION grupo5:" + signature
              url = "https://integracion-2017-dev.herokuapp.com/bodega/moveStock"
              move = HTTP.auth(auth_header).headers(:accept => "application/json").post(url, json: { productoId: product["_id"], almacenId: almacen_despacho })
            end
          end
        end

    #Despacho de producto.
    def delivery(sku, quantity, almacen_recepcion, ordenId, precio)
      secret = "W1gCjv8gpoE4JnR" # desarrollo
      bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega"
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      orden = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/obtener/#{ordenId}")
      # buscar precio correspondiente a la orden de compra
      precio = orden["precioUnitario"]

      # Unidades a despachar, ya han sido transferidas al almacén de despacho.
      almacenId = "590baa76d6b4ec00049028b2"

      #Hacer la request la cantidad de veces necesaria
      while quantity > 0 do
        limit = (quantity if quantity < 200) || 200
        url = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=#{almacenId}&sku=#{sku}&limit=#{limit}"
        data = "GET#{almacenId}#{sku}"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature

        # Obtener productos
        products = HTTP.auth(auth_header).headers(:accept => "application/json").get(url)
        if (products.parse.length < 200) && (products.parse.length < quantity)
           render ({json: "Faltan #{quantity-products.parse.length} productos en almacen despacho, para completar pedido", status: 422})
           return
        end
        quantity -= products.parse.length

        # Request moveStockBodega
        if products.code == 200
          products.parse.each do |product|
            productoId = product["_id"]
            data = "POST#{productoId}#{almacen_recepcion}" # Almacen de recepcion comprador?
            hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
            signature = Base64.encode64(hmac).chomp
            auth_header = "INTEGRACION grupo5:" + signature
            url = "https://integracion-2017-dev.herokuapp.com/bodega/moveStockBodega"
            deliver = HTTP.auth(auth_header).headers(:accept => "application/json").post(url, json: { productoId: productoId, almacenId: almacen_recepcion, oc: ordenId, precio: precio})
            if deliver.code != 200
              render ({json: "No se pudo procesar despacho", status: 422})
              return
            end
          end
        end
      end
      render ({json: "Orden despachada", status: 200})
    end

    def receive
        #The provider accepts a PO that we created.
        if !(params.has_key?(:payment_method) || params.has_key?(:id_store_reception))
            render json: {error: "Formato de Body incorrecto"}, status:400
            if !(params.has_key?(:payment_method))
                render json: {error: "Falta método de pago"}, status:400
            elsif !(params.has_key?(:id_store_reception))
                render json: {error: "Falta bodega de recepción"}, status:400
        else
            if params[:payment_method] = "" || params[:payment_method].nil?
                render json: {error: "Falta método de pago"}, status:400
            elsif params[:id_store_reception] = "" || params[:id_store_reception].nil?
                render json: {error: "Falta bodega de recepción"}, status:400
            else
                poid = params["_id"]
                orden = HTTP.get(base_route+"obtener/"+poid)
                if orden.status.code != 200
                    render json: {error: "Orden de compra inexistente"}, status:404
                else

                    ordenParseada = JSON.parse orden.to_s
                    id = ordenParseada[0]["_id"]
                    cliente = ordenParseada[0]["cliente"]
                    proveedor = ordenParseada[0]["proveedor"]
                    sku = ordenParseada[0]["sku"]
                    fechaEntrega = ordenParseada[0]["fechaEntrega"]
                    cantidad = ordenParseada[0]["cantidad"]
                    cantidadDespachada = ordenParseada[0]["cantidadDespachada"]
                    precioUnitario = ordenParseada[0]["precioUnitario"]
                    canal = ordenParseada[0]["canal"]
                    estado = ordenParseada[0]["estado"]
                    notas = ordenParseada[0]["notas"]
                    rechazo = ordenParseada[0]["rechazo"]
                    anulacion = ordenParseada[0]["anulacion"]
                    created_at = ordenParseada[0]["created_at"]
                    stock = Stock.find_by(sku: sku)
                    prod = Product.find_by(sku: sku)

                    if stock == nil
                        estado = "rechazada"
                        rechazo = "sku inválido"
                        PurchaseOrder.create(poid: poid, payment_method: " ", payment_option: " ",
                                             date: DateTime.now ,sku: sku, amount: cantidad,
                                             status: estado, delivery_date: fechaEntrega,
                                             unit_price: precioUnitario, rejection: rechazo)
                        HTTP.header(accept: "application/json").put(base_route+"rechazar/"+poid,
                         json: {_id: poid, rechazo: rechazo})
                        HTTP.header(accept: "application/json").patch(group_route(cliente) +poid + '/rejected',
                         json: {cause: rechazo})


                    elsif Time.now.to_f*1000 + product_time*60000*60 >= fechaEntrega
                        estado = "rechazada"
                        rechazo = "No alcanza a estar la orden"
                        PurchaseOrder.create(poid: poid, payment_method: " ", payment_option: " ",
                                             date: DateTime.now ,sku: sku, amount: cantidad,
                                             status: estado, delivery_date: fechaEntrega,
                                             unit_price: precioUnitario, rejection: rechazo)
                        HTTP.header(accept: "application/json").put(base_route+"rechazar/"+poid,
                         json: {_id: poid, rechazo: rechazo})
                        HTTP.header(accept: "application/json").patch(group_route(cliente) +poid + '/rejected',
                         json: {cause: rechazo})

                    else
                        estado = "aceptada"
                        PurchaseOrder.create(poid: poid, payment_method: " ", payment_option: " ",
                                             date: DateTime.now ,sku: sku, amount: cantidad,
                                             status: estado, delivery_date: fechaEntrega,
                                             unit_price: precioUnitario, rejection: " ")
                        HTTP.header(accept: "application/json").put(base_route+"recepcionar/"+poid,
                         json: {_id: poid})
                        HTTP.header(accept: "application/json").patch(group_route(cliente) +poid + '/accepted')
                        en_stock = get_stock_by_sku(sku)
                        faltante = cantidad-en_stock
                        if faltante > 0
                            # mover stock a despacho para reservar
                            tiempo_espera = produce_and_supplying(sku, faltante, fechaEntrega)
                            sleep((tiempo_espera-Time.now.to_f*1000)/1000)
                            # mover lo que faltaba a despacho
                            delivery(sku, cantidad, params[:id_store_reception], poid, precioUnitario)
                        else
                            # mover cantidad a despacho
                            delivery(sku, cantidad, params[:id_store_reception], poid, precioUnitario)
                        end

                    end
                end
            end
        end
    end

    private

    def product_time(prod)
        time = prod.time
        max_t = 0
        prod.supplies.each do |supply|
            if supply.time > max_t
                max_t = supply.time
            end
        end
        time += max_t + 1
        time.to_i
    end

    def group_route(client)
        'http://integra17-' + client + '.ing.puc.cl/purchase_orders/'
    end

    def get_stock_by_sku(sku)
        stock_final = 0
        secret = "W1gCjv8gpoE4JnR" # desarrollo
        bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega/" # desarrollo
        #Mandar a la bodega. Get sku de stock.
        data = "GET"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        # pedimos el arreglo de almacenes
        almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get(bodega_sist + "almacenes")
        if almacenes.code == 200
            almacenesP = JSON.parse almacenes.to_s
            almacenesP.each do |almacen|
                if !almacen["despacho"] && !almacen["pulmon"]
                    data += almacen["_id"]
                    products = HTTP.auth(auth_header).headers(:accept => "application/json").get(bodega_sist + "skusWithStock?almacenId=" + almacen["_id"])
                    if products.code == 200
                        productsP = JSON.parse products.to_s
                        productsP.each do |product|
                            if product["_id"]["sku"] == sku
                                stock_final += product["total"]
                            end
                        end
                    end
                end
            end
        end
        return stock_final
    end

    #B2B
    #CLiente te manda una orden de compra.(POController)
    #Getskuwithstock en bodega.
    #Decido si tengo o no tengo. //Decisión de aceptación de OC.
    #Si se rechaza
        # se rechaza la orden de compra y se informa el rechazo//rechazarOC(APi-->Sistema de OC) //InformaRechazo ( AP--> Cliente)

    #Si la aceptamos//recepcionarOC(Api --> Sistema de OC)
    #Informa aceptación de OC al cliente//
    #Se llama a rpoduccion y abastecimiento. // producir OC.
    #Despacho de producto.
        #Muevo Stock a Bodega de despacho.
        #For para todos los productos. Máximo de capacidad
        # Si es muy grnade se hacen 2 despachos, etc.
        #Hasta terminar el despacho. //despacharStock.
    #Si hay error en el despchao
        #Haga producción y abastecimiento denuevo.
    #Si estáok
        #Notifica orden Despachada.




end
