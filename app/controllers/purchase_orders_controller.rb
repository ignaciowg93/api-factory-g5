class PurchaseOrdersController < ApplicationController
    require 'http'
    require 'digest'
    base_route = "https://integracion-2017-dev.herokuapp.com/oc/"

    def new
        @purchase_order = PurchaseOrder.new
    end


    def receive
        #The provider accepts a PO that we created.
        if !(params.has_key?(:payment_method) && params.has_key?(:id_store_reception))
            render json: {error: "Formato de Body incorrecto"}, status:400
            if !(params.has_key?(:payment_method))
                render json: {error: "Falta método de pago"}, status:400
            elsif !(params.has_key?(:id_store_reception))
                render json: {error: "Falta bodega de recepción"}, status:400
        else
            if params[:payment_method].empty? || params[:payment_method].nil?
                render json: {error: "Falta método de pago"}, status:400
            elsif params[:id_store_reception].empty? || params[:id_store_reception].nil?
                render json: {error: "Falta bodega de recepción"}, status:400
            else
                poid = params["_id"]
                orden = HTTP.get(base_route+"obtener/"+poid)
                if orden.status.code != 200
                    render json: {error: "Orden de compra inexistente"}, status:404
                else
                    render json:{ok: "OC recibida exitosamente"} , status:201

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


                    elsif Time.now + product_time.hours >= fechaEntrega.to_date
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
                        if cantidad > get_stock_by_sku(sku)
                            # llamar a produce(sku)
                            end
                        end
                    end
                end
            end
        end
    end


## BUYING

    def accepted
        @purchase_order = PurchaseOrder.find_by(_id: params[:id])
        if @purchase_order.status == "creada"
            oc = HTTP.headers(:accept => "application/json").get('https://integracion-2017-dev.herokuapp.com/oc/obtener/' + params[:id])
            if oc.code == 200
                orden_compra = oc.parse[0]
                if orden_compra["estado"] == "aceptada"
                  puts("bbb")
                    if @purchase_order
                      puts("ccc")
                        @purchase_order.status = "aceptada"
                        if @purchase_order.save!
                            render json: {ok: "Resolución recibida exitosamente" }, status:200
                        end
                    end
                else
                  puts("a versh")
                    render json: {error: "Orden de compra No se encuentra aceptada en el sistema"}, status: 400
                end
            else
                render json: {error: "Orden de compra no encontrada"}, status:404
            end
        else
            render json: {error: "Orden de Compra ya resuelta"}, status: 403
        # The provider rejects a PO created by us. Check its existance.
        end
    end

    def rejected

        if (params.has_key?(:cause))
            @causa = params[:cause]
            if (@causa == "")
                render json: {error: "Debe entregar una razón de rechazo"}, status: 400
            else
                if @causa.nil?
                    render json: {error: "Debe entregar una causa distinta de nula"},status:400
                end
            end
        else
            render json: {error: "Formato de body incorrecto"},status: 400
        end
        @purchase_order = PurchaseOrder.find_by(_id: params[:id])
        if @purchase_order.status == "creada"
            oc = HTTP.headers(:accept => "application/json").get('https://integracion-2017-dev.herokuapp.com/oc/obtener/' + params[:id])
            if oc.code == 200
                orden_compra = oc.parse
                if orden_compra["estado"]== "rechazada"
                    if @purchase_order
                        @purchase_order.status = "rechazada"
                        if @purchase_order.save!
                            render json: {ok: "Resolución recibida exitosamente" }, status:200
                        end
                    end
                else
                    render json: {error: "ORden de compra No se encuentra aceptada en el sistema"}, status: 400
                end
            else
                render json: {error: "Orden de compra no encontrada"}, status:404
            end
        else
            render json: {error: "Orden de Compra ya resuelta"}, status: 403
        # The provider rejects a PO created by us. Check its existance.
        end
    end

    def create(sku)
        ## Tenemos que generarla nosotros , por lo tanto los parametros entrar desde nuestra BDD
    end




    def purchase_order_params
        params.permit( :purchase_order,:id ,:payment_method , :payment_option, :rejection, :poid)
    end

    def set_purchase_order
        @purchase_order = PurchaseOrder.find_by(poid: params[:id])
    end

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


    #TODO
    #When a Oc is creaed we have to check its existance in the OC server. If not return a 404.




    #TODOS2
    #Crear orden de compra, basado en el Cliente recibido por ApplicationController.Máximo 5000 por orden de compra.
    #Decidir loop de ordenes de compra. Ver errores de rechazos con la ordenes de compra.
    #Crear orden de compra ( Sistem Orden de compra). // Crear Orden De Compra
    #Mandar orden de compra al cliente (B2B). //Enviar Orden De Compra
    #Recibir apruebo o rechazo de la orden  //
    # Frente a rechazo mapear los proveedores para budcar siguiente posible proveedor Y volver a tratar.
    #Una vez creada y aceptada ,Devolverte a API, con el id de OC.
    #Desde la APi de marca como despachada



end
