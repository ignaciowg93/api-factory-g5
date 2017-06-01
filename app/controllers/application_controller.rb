require "http"
require 'digest'


class ApplicationController < ActionController::Base
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_exception
    rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique_exception
    rescue_from ActiveRecord::RecordInvalid,with: :record_invalid_exception
    rescue_from ActionController::RoutingError, with: :route_exception
    before_action :get_almacenes


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

    #retornar una lista ordenada en base a precio con id_seller, precio unitarios, tiempo, y stock
    # FUNCIONANDO
    def quote_a_price(sku_prod, sku_insumo, cant) #sku_insumo
      # Hacer un for de búsqueda, por lo productos.
      # ---
      # sku_prod = '11'
      # sku_insumo = '4'
      # cant = 10
      # ---
      supplier_list = (Product.find_by sku: sku_prod).supplies.where(:sku => sku_insumo)

      #current_min_price = "0" # nosotros tenemos en string, pero debiera ser INT
      sorted_suppliers = Array.new
      #iterar sobre los distintos vendedores
      supplier_list.each do |supplier|
        supplier.sellers.each do |supplier_seller|
          seller = (Client.find_by gnumber: supplier_seller.seller)
          route = seller.url + "products"
          @response = HTTP.headers("X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").get(route)
          # Probar con la otra posible ruta
          route = seller.url + 'api/publico/precios'
          @response = HTTP.headers("X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").get(route) if @response.code !=200 || (@response["Content-Type"] != "application/json; charset=utf-8")
          if @response.code == 200
            if @response["Content-Type"] == "application/json; charset=utf-8"
              begin
                products_list = @response.parse
                # obtengo la lista de productos del seller y cotizo
                products_list.each do |prod|
                  if prod["sku"] == sku_insumo.to_i || prod["sku"] == sku_insumo
                    if prod["stock"] != nil
                      prod2 = prod["stock"]
                    else
                      prod2 = 0
                    end
                    precio = prod["price"] || prod["precio"]
                    sorted_suppliers << [seller.name, precio, supplier_seller.time, prod2]
                    #puts sorted_suppliers
                  end
                end
              rescue JSON::ParserError => e
                puts("Error en parse: #{e}")
              end
            end
          end
        end
      end
      sorted_suppliers.sort!{|a,b| a[2] <=> b[2]}
      sorted_suppliers
    end
      #Después de aceptada la OC,


      #Mandar al proveedor el Id del almacen a recepcionar los productos de la OC asociada.
      # -> ALGUNOS LO MANDAN EN EL MENSAJE DE OC EMITIDA

      #Esperar notificación de despacho desde proveedor.

    def abastecimiento_mp(sku_prod, sku_insumo, cant_mp, fecha_max, alm_recep_id)
      #---
      #sku_prod = "5"
      #sku_insumo = "49"
      #cant_mp = 300
      #fecha_max = 1793214596281
      #alm_recep_id = "590baa76d6b4ec00049028b1"
      #---
      #oc_this_time = Array.new
      # Cotizar
      sellers = quote_a_price(sku_prod, sku_insumo, cant_mp)

      # mandar OC hasta cubrir cant_mp confirmada
      sellers.each do |seller|
        oc = ""
        # Se envia orden de compra por el stock disponible completo del proveedor
        loop do
          sleep(15)
          oc = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_oc +'crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => seller[0], :sku => sku_insumo, :fechaEntrega => fecha_max, :cantidad => seller[3], :precioUnitario => seller[1], :canal => "b2b" })
          break if oc.code == 200
        end
        # agrego entrada (nueva OC) en la tabla y notifico
        seller_addr =  (Client.find_by name: seller[0]).url + "purchase_orders/" + oc.parse["_id"]
        notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").put(seller_addr, :json => { :payment_method => "contra_factura", :id_store_reception  => alm_recep_id})
        PurchaseOrder.create(_id: oc.parse["_id"], client: oc.parse["cliente"], supplier: oc.parse["proveedor"], sku: oc.parse["sku"], delivery_date: oc.parse["fechaEntrega"], amount: oc.parse["cantidad"], delivered_qt: oc.parse["cantidadDespachada"], unit_price: oc.parse["precioUnitario"], channel: oc.parse["canal"], status: oc.parse["estado"])
        # esperar apruebo o rechazo

        loop do
          oc = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_oc + "obtener/#{oc.parse["_id"]}")
          sleep(15)
          break if oc.parse[0]["estado"] == "aceptada"
          sleep(60) if oc.code == 429
        end
        # Orden aceptada
        cant_mp -= seller[3]
        break if cant_mp <= 0
      end
      while cant_mp > 0
        # Si despues de pedir todo el stock disponible de los grupos, todavia faltan unidades, mandar a producir.
        sellers.each do |seller|
          oc = ""
          loop do
            oc = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_oc + 'crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => seller[0], :sku => sku_insumo, :fechaEntrega => fecha_max, :cantidad => cant_mp, :precioUnitario => seller[1], :canal => "b2b" })
            break if oc.code == 200
          end
          # agrgo entrada en la tabla (inicializada en id ) y notifico
          seller_addr = (Client.find_by name: seller[0]).url + "purchase_orders/" + oc.parse["_id"] # ruta debiera sacarse de una base de datos
          notification = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").put(seller_addr, :json => { :payment_method => "contra_factura", :id_store_reception  => alm_recep_id})
          PurchaseOrder.create(_id: oc.parse["_id"], client: oc.parse["cliente"], supplier: oc.parse["proveedor"], sku: oc.parse["sku"], delivery_date: oc.parse["fechaEntrega"], amount: oc.parse["cantidad"], delivered_qt: oc.parse["cantidadDespachada"], unit_price: oc.parse["precioUnitario"], channel: oc.parse["canal"], status: oc.parse["estado"])
          # esperar apruebo o rechazo
          loop do
            oc = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_oc + "obtener/#{oc.parse["_id"]}")
            sleep(15)
            break if oc.parse[0]["estado"] == "aceptada"
            sleep(60) if oc.code == 429
          end
          cant_mp = 0
        end
      end
      #oc_this_time.sort!{|a,b| b["fechaEntrega"] <=> a["fechaEntrega"]}
      # FIXME: para sprint 4, cuando se notifique despacho
      # retornar la lista de OCs para después verificar los despachos
      #return oc_this_time
    end

    # Producción y abastecimiento
    def produce_and_supplying (sku, qty, fecha_max)

      prdt = (Product.find_by sku: sku)
      lot = prdt.lot
      puts "PRODUCCION"
      puts("Lot: #{lot}")

      # if qty <= lot
      #   @remaining = lot
      #   mult = 1
      #   puts("A: #{@remaining}")
      # else
      #   mult = 2
      #   @remaining = lot * mult
      #   while @remaining < qty
      #     mult += 1
      #     @remaining = lot * mult
      #     #quizás queda mejor con @remaining += lot
      #   end
      # end

      # Definir lote de produccion
      @remaining = lot
      while @remaining / qty < 1 do
        @remaining += lot
      end
      n_lotes = @remaining/lot

      puts ("Producir: #{n_lotes} lote(s) ")

      # Buscar materias primas si producto es procesado
      if prdt.processed == 1
        # Preparación para producir
        my_supplies = prdt.supplies
        # my_supplies_r = prdt.supplies
        # current_supply_sku = ""
        # my_supplies = Array.new
        # my_supplies_r.each do |supply|
        #   if current_supply_sku != supply.sku
        #     my_supplies.push([supply.sku, supply.requierment * n_lotes])
        #     current_supply_sku = supply.sku
        #   end
        # end

        # Revisar stock para cada materia prima
        # Reservar
        # Mover a despacho cuando se tengan todas las unidades
        # Fecha entrega de las materias primas
        fecha = fecha_max - prdt.time*3600 - 3600
        my_supplies.each do |supply|
          # En stock esta solo stock disponible (stock reservado esta restado)
          stock = get_stock_by_sku(supply)
          puts "Stock: #{stock}"
          if supply.requierment * n_lotes >= stock
            remain = supply.requierment * n_lotes - stock
            # Abastecerse del resto
            #oc_list = abastecimiento_mp(sku, supply.sku, remain, fecha, Rails.configuration.recepcion_id)
            abastecimiento_mp(sku, supply.sku, remain, fecha, Rails.configuration.recepcion_id)
            # La idea es que me notifiquen que llegó, pero por ahora debiera ser un sleep del tiempo nomás
          end
          # Se reserva todo, aunque no haya llegado
          supply.stock_reservado += supply.requierment * n_lotes
          supply.save
        end

        # Se espera por las ordenes de compra, segun la fecha
        # FIXME: ir accediendo al estado de las ordenes, porque pueden estar despachadas mucho antes.
        sleep((Time.parse(fecha) - Time.now) + 1800)
        # Verificar que ha llegado todo.
        # Get sku

        # Mover unidades a almacen de despacho
        # Cuando se mueven, ya no estan reservadas, porque no se busca en despacho
        my_supplies.each do |supply|
          move_to_despacho(supply.requierment * n_lotes, supply.sku)
          supply.stock_reservado -= supply.requierment * n_lotes
          supply.save
        end

=begin
        # data = "GET"
        # worked_st = 0
        # # pedimos el arreglo de almacenes
        # while worked_st == 0
        #   almacenes = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/almacenes")
        #   if almacenes.code == 200
        #     worked_st = 1 # (no es necesario intentarlo de nuevo)
        #     #armo lista ordenada de almacenes
        #     sorted_almacenes = Array.new
        #     almacenes.parse.each do |almacen|
        #       if almacen["despacho"] == false && almacen["recepcion"] == false && almacen["pulmon"] == false # es almacen intermedio
        #         sorted_almacenes.push([almacen["_id"], 1])
        #       elsif almacen["despacho"] == false && almacen["recepcion"] == true # es recepción
        #         sorted_almacenes.push([almacen["_id"], 2])
        #         @almacen_recep_id = almacen["_id"]
        #       elsif almacen["despacho"] == false && almacen["recepcion"] == false # es pulmón
        #         sorted_almacenes.push([almacen["_id"], 3])
        #       else # es despacho
        #         sorted_almacenes.push([almacen["_id"], 4])
        #       end
        #     end
        #     sorted_almacenes.sort!{|a,b| a[1] <=> b[1]}
        #     sorted_almacenes.each do |s_almacen|
        #       #busco en cada almacen
        #       data = "GET" + s_almacen[0]
        #       route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId=" + s_almacen[0]
        #       products_array = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route_to_get)
        #       if products_array.code == 200
        #         # comparo con lo que necesito
        #         products_array.parse.each do |product|
        #           my_supplies.each do |supply|
        #             if supply.requierment > 0 # si todavía no he alcanzado el total necesario
        #               if supply[0] == product["_id"] #??
        #                 #mover a despacho (muevo directo)
        #                 data = "GET" + s_almacen[0] + supply[0]
        #                 route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + s_almacen[0] + "&sku=" + supply[0] + "&limit=200"
        #                 while supply[1] > 0
        #                   puts("while quedan")
        #                   prod_ids = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route_to_get)
        #                   #mover a ID DESPACHO y restarle a quedan
        #                   if prod_ids.code == 200
        #                     prod_ids.each do |prod|
        #                       data = "POST" + prod["_id"] + sorted_almacenes.last[0]
        #                       route_to_post = "https://integracion-2017-dev.herokuapp.com/bodega/moveStock"
        #                       while romper2 > 0
        #                         move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route_to_post, :json => { :productoId => prod["_id"], :almacenId => sorted_almacenes.last[0] })
        #                         if move.code = 200
        #                           supply[1] -= 1
        #                           romper = 0
        #                         elsif move.code == 429
        #                           sleep(60)
        #                         end
        #                       end
        #                     end
        #                   elsif prod_ids.code == 400
        #                     break
        #                   elsif prod_ids.code == 429
        #                     sleep(60)
        #                   end
        #                 end
        #               end
        #             end
        #           end
        #         end
        #       end
        #     end
        #   elsif almacenes.code == 429
        #     #esperar 1 minuto
        #     sleep(60)
        #   end
        # end
=end

=begin
      #Verificar stock mínimo de producción.
      #   my_supplies.each do |supply|
      #     if supply[1] > 0 # no tengo todo
      #       #Llamar al abastecimiento de MP.(Block anterior)
      #       #puts("#{sku}, #{supply[0]}, #{supply[1]}, #{fecha_max}, #{@almacen_recep_id}")
      #       oc_list = abastecimiento_mp(sku, supply[0], supply[1], fecha_max, @almacen_recep_id)
      #       puts("retorno: #{oc_list} fin")
      #       # la idea es que me notifiquen que llegó, pero por ahora debiera ser un sleep del tiempo nomás
      #       puts("ahora sleep")
      #       #FIXME
      #       sleep((Time.parse(oc_listm[0]["fechaEntrega"]) - Time.now) + 1800)
      #       #sleep(5)
      #       puts("ya fue el sleep")
      #       #while (Invoice_reg.find_by oc_id: oc).delivered == 0
      #       #end
      #       #mover a despacho(buscar en recepcion o pulmón)
      #       sorted_almacenes.each do |s_almacen|
      #         #busco en cada almacen
      #         if s_almacen[1] == 2 || s_almacen[1] == 3 #solo en recepción y pulmón
      #
      #           data = "GET" + s_almacen[0]
      #           route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId=" + s_almacen[0]
      #           worked_st2 = 0
      #           while worked_st2 == 0
      #             puts("while worked_st2")
      #             sleep(2)
      #             products_array = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route_to_get)
      #             if products_array.code == 200
      #               worked_st2 = 1
      #               # comparo con lo que necesito
      #               puts products_array
      #               products_array.parse.each do |product| # le sacamos un parse que tenia
      #                 my_supplies.each do |supply|
      #                   if supply[1] > 0 # si todavía no he alcanzado el total necesario
      #                     if supply[0] == product["_id"]
      #                       #mover a despacho (muevo directo)
      #                       data = "GET" + s_almacen[0] + supply[0]
      #                       limit = (supply[1] if supply[1] < 200) || 200
      #                       route_to_get = "https://integracion-2017-dev.herokuapp.com/bodega/stock?almacenId=" + s_almacen[0] + "&sku=" + supply[0] + "&limit=#{limit}"
      #                       # quedan = product["total"]
      #                       while supply[1] > 0
      #                         puts("while quedan 2")
      #                         sleep(2)
      #                         prod_ids = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(route_to_get)
      #                         #mover a ID DESPACHO y restarle a quedan
      #                         if prod_ids.code == 200
      #                           prod_ids.parse.each do |prod|
      #                             data = "POST" + prod["_id"] + sorted_almacenes.last[0]
      #                             route_to_post = "https://integracion-2017-dev.herokuapp.com/bodega/moveStock"
      #                             romper = 1
      #                             while romper > 0 && supply[1]>0
      #                               move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route_to_post, :json => { :productoId => prod["_id"], :almacenId => sorted_almacenes.last[0] })
      #                               if move.code == 200
      #                                 supply[1] -= 1
      #                                 romper = 0
      #                               elsif move.code == 429
      #                                 sleep(60)
      #                               end
      #                             end
      #                           end
      #                         elsif prod_ids.code == 400
      #                           break
      #                         elsif prod_ids.code == 429
      #                           sleep(60)
      #                         end
      #                       end
      #                     end
      #                   end
      #                 end
      #               end
      #             elsif products_array.code == 429
      #               #esperar 1 minuto
      #               sleep(60)
      #             end
      #           end
      #         end
      #       end
      #     end
      #   end
      #   # fin preparación para producir

      # end

=end
      end

      #Ir y producir stock, máximo 5000 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.
      ### Creo que no está haciendo 5000 por ciclo. Está haciendo menos.
      puts("ahora a fabricar")
      sleep(4)
      #transferir $$ a fábrica
      puts(@remaining)
      longest_time = Time.now
      while @remaining >= 0
        # request de producción
        if @remaining > 5000
          to_produce = @remaining
          while to_produce > 5000
            to_produce -= lot
          end
        else
          to_produce = @remaining
        end
        puts("ahora to_produce= #{to_produce}")
        #pagar producción
        data = "GET"
        #puts("antes")
        monto = to_produce * prdt.price.to_i
        #puts("monto= #{monto}")
        factory_account2 = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "/fabrica/getCuenta")
        #puts("factory to_s: #{factory_account2.to_s}")
        factory_account = factory_account2.parse["cuentaId"]
        #puts("factory_account: #{factory_account}")
        trx1 = HTTP.headers(:accept => "application/json").put(Rails.configuration.base_route_banco + "trx", :json => { :monto => monto, :origen => "590baa00d6b4ec0004902471", :destino => factory_account })
        aviso = trx1.to_s
        #puts("trx1: #{aviso}")
        #Producir
        if trx1.code == 200
          data = "PUT" + sku + to_produce.to_s + trx1.parse["_id"]
          puts("ahora remaining: #{@remaining}")
          puts("p_order antes")
          production_order = HTTP.auth(generate_header(data)).headers(:accept => "application/json").put(Rails.configuration.base_route_bodega + "/fabrica/fabricar", :json => { :sku => sku, :cantidad => to_produce, :trxId =>  trx1.parse["_id"]})
          puts("p_order dsps")
          @production_order = ProductionOrder.new
          @production_order.sku = sku
          @production_order.amount =  to_produce
          if @production_order.save!
            if production_order.code == 200
              puts("en el if: #{production_order.parse}")
              # podría quizás guardar la fecha esperada de entrega, estado despachado, etc.
              # guradar orden de produccion
              if longest_time < production_order.parse["disponible"]
                longest_time = production_order.parse["disponible"]
              end
              @remaining -= 5000
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

      # Nosotros no hacemos move_to_despacho(qty, sku)

      puts("#{longest_time}")
      #retorno fecha en que todo lo fabricado debería llegar
      return longest_time
    end

    def move_to_despacho(qty, sku)
      products = ""
      remaining = qty
      # Indica si es necesario o no llegar al pulmon a revisar
      search_pulmon = false
      while remaining > 0 do
        # Buscar en recepcion
        if !search_pulmon
          data = "GET" + Rails.configuration.recepcion_id + sku #GETalmacenIdsku
          url = Rails.configuration.base_route_bodega +"stock?almacenId=" + Rails.configuration.recepcion_id + "&sku=" + sku
          loop do
            products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
            break if products.code == 200
            sleep(60) if products.code == 429
          end
          search_pulmon = true if products.parse.empty?
        else
          # Buscar en pulmon
          data = "GET" + Rails.configuration.pulmon_id + sku #GETalmacenIdsku
          url = Rails.configuration.base_route_bodega +"stock?almacenId=" + Rails.configuration.pulmon_id + "&sku=" + sku
          loop do
            products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
            break if products.code == 200
            sleep(60) if products.code == 429
          end
        end

        products.parse.each do |product|
          data = "POST" + product["_id"] + Rails.configuration.despacho_id #POSTproductoIdalmacenId
          url = Rails.configuration.base_route_bodega + "moveStock"
          move = ""
          loop do
            move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(url, json: { productoId: product["_id"], almacenId: Rails.configuration.despacho_id })
            break if move.code == 200
            sleep(60) if move.code == 429
          end
          remaining -= 1
        end
      end
    end

    #Despacho de producto.
    def delivery(sku, quantity, almacen_recepcion, ordenId, precio)
      data = "GET"
      orden = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get( Rails.configuration.base_route_bodega + "obtener/#{ordenId}")
      # buscar precio correspondiente a la orden de compra
      precio = orden["precioUnitario"]

      # Unidades a despachar, ya han sido transferidas al almacén de despacho.
      almacenId = "590baa76d6b4ec00049028b2"

      #Hacer la request la cantidad de veces necesaria
      while quantity > 0 do
        limit = (quantity if quantity < 200) || 200
        url = Rails.configuration.base_route_bodega + "stock?almacenId=#{almacenId}&sku=#{sku}&limit=#{limit}"
        data = "GET#{almacenId}#{sku}"

        # Obtener productos
        products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
        # if (products.parse.length < 200) && (products.parse.length < quantity)
        #    render ({json: "Faltan #{quantity-products.parse.length} productos en almacen despacho, para completar pedido", status: 422})
        #    return
        # end
        quantity -= products.parse.length

        # Request moveStockBodega
        if products.code == 200
          products.parse.each do |product|
            productoId = product["_id"]
            data = "POST#{productoId}#{almacen_recepcion}" # Almacen de recepcion comprador?
            url = Rails.configuration.base_route_bodega + "moveStockBodega"
            deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(url, json: { productoId: productoId, almacenId: almacen_recepcion, oc: ordenId, precio: precio})
            # if deliver.code != 200
            #   render ({json: "No se pudo procesar despacho", status: 422})
            #   return
            # end
          end
        end
      end
      render ({json: "Orden despachada", status: 200})
    end

    def receive
          # Receive purchase order
          # Verified body request
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
                  response = HTTP.headers(accept: "application/json").get(Rails.configuration.base_route_oc+"obtener/"+poid)
                  orden = JSON.parse response.to_s
                  puts orden

                  if response.status.code != 200
                      render json: {error: "Orden de compra inexistente"}, status:404
                  else
                      render json:{ok: "OC recibida exitosamente"} , status:201
                      puts "orden recibida"

                      Thread.new do
                        id = orden[0]["_id"]
                        cliente = orden[0]["cliente"]
                        proveedor = orden[0]["proveedor"]
                        sku = orden[0]["sku"]
                        fechaEntrega = orden[0]["fechaEntrega"]
                        cantidad = orden[0]["cantidad"]
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
                          PurchaseOrder.create(_id: poid, #payment_method: " ", payment_option: " ", ,sku: sku, amount: cantidad,
                                               status: estado, delivery_date: fechaEntrega,
                                               unit_price: precioUnitario, rejection: rechazo)
                          HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_oc+"rechazar/"+poid,
                           json: {_id: poid, rechazo: rechazo})

                      # No hay stock y el tiempo de produccion excede la fecha de entrega
                      elsif en_stock < cantidad.to_i && (Time.now + product_time(prod)*3600) >= fechaEntrega
                          estado = "rechazada"
                          rechazo = "No alcanza a estar la orden"
                          PurchaseOrder.create(_id: poid, sku: sku, amount: cantidad,
                                               status: estado, delivery_date: fechaEntrega,
                                               unit_price: precioUnitario, rejection: rechazo)
                          HTTP.headers(accept: "application/json").put(Rails.configuration.base_route_oc+"rechazar/"+poid,
                           json: {_id: poid, rechazo: rechazo})
                          HTTP.headers(accept: "application/json").patch(group_route(grupo) +poid + '/rejected',
                           json: {cause: rechazo})

                      else
                          estado = "aceptada"
                          PurchaseOrder.create(_id: poid, #payment_method: " ", payment_option: " ",
                                               sku: sku, amount: cantidad,
                                               status: estado, delivery_date: fechaEntrega,
                                               unit_price: precioUnitario, rejection: " ")
                          response = HTTP.headers(accept: "application/json").post(Rails.configuration.base_route_oc+"recepcionar/"+poid,
                           json: {_id: poid})
                          HTTP.headers(accept: "application/json").patch(group_route(grupo) +poid + '/accepted')
                          faltante = cantidad - en_stock
                          # Reservar cantidad
                          prod.stock_reservado += cantidad
                          prod.save
                          puts "Orden aceptada"
                          puts "En stock: #{en_stock}"
                          puts "Producir: #{faltante}"
                          puts "Reservado: #{prod.stock_reservado}"
                          if faltante > 0
                              tiempo_espera = produce_and_supplying(sku, faltante, Time.parse(fechaEntrega).to_f*1000)
                              puts "Tiempo de espera produccion: #{tiempo_espera}"
                              sleep((Time.parse(tiempo_espera) - Time.now) + 1800) # 30 minutos de holgura
                          end
                          move_to_despacho(cantidad, sku)
                          delivery(sku, cantidad, params[:id_store_reception], poid, precioUnitario)
                          # Reestablecer disponibilidad
                          prod.stock_reservado -= cantidad
                          prod.save
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
          supply.sellers.each do |seller|
            if seller.time > max_t
                max_t = seller.time
            end
          end
        end
        time += max_t + 1
        time.to_i
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

    # Se recibe el producto o supply del sku
    def get_stock_by_sku(producto)
        sku = producto.sku
        stock_final = 0
        response = ""
        @almacenes.each do |almacen|
          # No busca en despacho
          break if almacen["despacho"]
          data = "GET#{almacen["_id"]}"
          loop do
            response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=" + almacen["_id"])
            break if response.code == 200
          end
          products = JSON.parse response.to_s
          products.each do |product|
            # Sku viene en id de producto
              if product["_id"] == sku
                  stock_final += product["total"]
              end
          end
        end
        # Se resta lo reservado
        # Si queda en negativo, se setea en cero.
        stock_final - producto.stock_reservado > 0 ? (stock_final - producto.stock_reservado) : 0
    end

    def get_almacenes
      data = "GET"
      response = ""
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        break if response.code == 200
        sleep(60) if response.code == 429
      end
      @almacenes = JSON.parse response.to_s
    end

    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
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
