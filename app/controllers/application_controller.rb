require "http"

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
    def quote_a_price(sku)
      # Hacer un for de búsqueda, por lo productos.
      my_supplies = (Product.find_by sku: sku).supplies
      current_supply_sku = ""
      current_min_price = 0
      supplier = ""
      my_supplies.each do |supply|
        #para saber que comparo para el mismo sku de insumo
        if current_supply_sku == supply.sku
        else
          #crear orden de compra
          proveedor = "5910c0910e42840004f6e685"
          punit = 5 # ¿nos entregan los precios unitarios o por lotes? -> debiera ser unitario pq no les compramos lotes
          cant = 5
          tiempo = Time.new(2017, 8, 31, 2, 2, 2).to_f * 1000
          oc = HTTP.headers(:accept => "application/json").put('https://integracion-2017-dev.herokuapp.com/oc/crear', :json => { :cliente => "5910c0910e42840004f6e684", :proveedor => proveedor, :sku => 17, :fechaEntrega => tiempo, :cantidad => cant, :precioUnitario => punit, :canal => "b2b" })
          if oc.code == 200
            oc_id = oc.parse["_id"]
            #mandar OC al proveedor escogido
            route_put = 'http://integra17-' + supplier + '.ing.puc.cl/purchase_orders/' + oc_id
            HTTP.put(route_put, :json => { :payment_method => "contado" })
            # revisar status code respuesta
          end
          # pasar a cotizar el siguiente insumo
          current_supply_sku = supply.sku
        end
        seller = supply.seller
        route = 'http://integra17-' + seller + '.ing.puc.cl/products'
        response = HTTP.get(route)
        if response.code == 200
          products_list = reponse.parse["productos"]
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
      #Elegir proveedor de compra. Mandar esta elección a orden de compra.
      #Después de aceptada la OC,
      #Mandar al proveedor el Id del alamcen a recepcionar los productos de la OC asociada.
      #Esperar notificación de despacho desde proveedor.
    end

    #Mandar a la bodega. Get sku de stock.
    #Te devuelve un SKU con todos los totales
    #Verificar stock mínimo de producción.
    #Si no
        #Llamar al abastecimiento de MP.(Block anterior)
    #Una vez con las materias primas, mover desde stock. Con el product id

    #Ir y producir stock, máximo 500 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.

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
