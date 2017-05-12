require "http"
require 'digest'

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
    def quote_a_price(sku, cant)
      # Hacer un for de búsqueda, por lo productos.
      my_supplies = (Product.find_by sku: sku).supplies
      current_supply_sku = ""
      current_min_price = "0" # nosotros tenemos en string, pero debiera ser INT
      supplier = ""
      my_supplies.each do |supply|
        #para saber que comparo para el mismo sku de insumo
        if current_supply_sku == supply.sku
        else
          #crear orden de compra
          proveedor = "5910c0910e42840004f6e685"  # esto debiéramos sacarlo de una base de datos previa
          punit = current_min_price # ¿nos entregan los precios unitarios o por lotes? -> debiera ser unitario pq no les compramos lotes
          tiempo = Time.new(2017, 8, 31, 2, 2, 2).to_f * 1000
          oc = HTTP.headers(:accept => "application/json").put('https://integracion-2017-dev.herokuapp.com/oc/crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => proveedor, :sku => 17, :fechaEntrega => tiempo, :cantidad => cant, :precioUnitario => punit, :canal => "b2b" })
          if oc.code == 200
            oc_id = oc.parse["_id"]
            #Elegir proveedor de compra. Mandar esta elección a orden de compra.
            route_put = 'http://integra17-' + supplier + '.ing.puc.cl/purchase_orders/' + oc_id
            HTTP.put(route_put, :json => { :payment_method => "contado" })
            # revisar status code respuesta
          end
          # pasar a cotizar el siguiente insumo
          current_supply_sku = supply.sku
        end
        seller = supply.seller
        route = 'http://integra17-' + seller + '.ing.puc.cl/products'
        @response = HTTP.get(route)
        if @response.code == 200
          products_list = @response.parse["productos"]
          # obtengo la lista de productos del seller y cotizo
          products_list.each do |prod|
            if prod["sku"] == current_supply_sku
              if prod["price"] < current_min_price
                current_min_price = prod["precio"]
                supplier = seller # se selecciona el más barato actual
              end
            end
          end
        end
      end
      #Después de aceptada la OC,


      #Mandar al proveedor el Id del alamcen a recepcionar los productos de la OC asociada.
      # -> ALGUNOS LO MANDAN EN EL MENSAJE DE OC EMITIDA

      #Esperar notificación de despacho desde proveedor.
    end

    def produce(sku, qty)
      my_supplies_r = (Product.find_by sku: sku).supplies
      current_supply_sku = ""
      my_supplies = Array.new
      my_supplies_r.each do |supply|
        if current_supply_sku != supply.sku
          #agregar al arreglo
          my_supplies.push([supply.sku, supply.requierment)

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
      # pedimos el arreglo de almacenes
      almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/almacenes")
      if almacenes.code == 200
        almacenes.parse.each do |almacen|
          #busco en cada almacen
          data = "GET" + almacen["_id"]
          hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
          signature = Base64.encode64(hmac).chomp
          auth_header = "INTEGRACION grupo5:" + signature
          products_array = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock", :json => { :almacenId => almacen["_id"] })
          if products_array.code == 200 # estoy asumiendo que 200 es el ok aquí
            # comparo con lo que necesito
            products_array.parse.each do |product|
              my_supplies.each do |supply|
                if supply[1] > 0 # si todavía no he alcanzado el total necesario
                  if supply[0] == product["_id"]
                    #lo muevo lo más posible
                    supply[1] -= product["total"] # dcto. de los restantes
                  end
                end
              end
            end
          end
        end
      end
      #Te devuelve un SKU con todos los totales
      #Verificar stock mínimo de producción.
      my_supplies.each do |supply|
        if supply[1] > 0 # no tengo todo
          #Llamar al abastecimiento de MP.(Block anterior)
        end
      end

      #Una vez con las materias primas, mover desde stock. Con el product id

      #Ir y producir stock, máximo 500 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.
      ramaining = qty
      #transferir $$ a fábrica
      trid = "abc"
      while remaining >= 0
        # autenticación
        data = "PUT" + sku + trid + remaining.to_s
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        # request de producción
        production_order = HTTP.auth(auth_header).headers(:accept => "application/json").put(bodega_sist + "fabrica/fabricar", :json => { :sku => sku, :trxid => trid, :cantidad => remaining })
        if production_order.code == 200
          remaining -= 500
        elsif production_order.code == 429
          #esperar 1 minuto
        end
      end
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
