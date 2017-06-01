require 'rufus/scheduler'
require "http"

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

def generate_header(data)
  hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
  signature = Base64.encode64(hmac).chomp
  auth_header = "INTEGRACION grupo5:" + signature
  auth_header
end

def quote_a_price(sku_prod, sku_insumo, cant) #sku_insumo
  # Hacer un for de búsqueda, por lo productos.
  # ---
  #sku_prod = '11'
  #sku_insumo = '4'
  #cant = 10
  # ---
  supplier_list = (Product.find_by sku: sku_prod).supplies.where(:sku => sku_insumo)
  #current_min_price = "0" # nosotros tenemos en string, pero debiera ser INT
  sorted_suppliers = Array.new
  #iterar sobre los distintos vendedores
  supplier_list.each do |supplier|
    supplier.sellers.each do |supplier_seller|
      #seller = supplier.seller
      seller = (Client.find_by gnumber: supplier_seller.seller)
      #route = 'http://integra17-' + seller + '.ing.puc.cl/products'
      route = seller.url + 'api/publico/precios'
      # route = "http://integra17-2.ing.puc.cl/products"
      @response = HTTP.headers("X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").get(route)
      # puts @response
      if @response.code == 200
        #puts @response["Content-Type"]
        if @response["Content-Type"] == "application/json; charset=utf-8"
          #VER POR CADA GRUPO
          #puts "hola"
          begin
            products_list = @response.parse
            # obtengo la lista de productos del seller y cotizo
            products_list.each do |prod|
              if prod["sku"] == sku_insumo
                if prod["stock"] != nil
                  prod2 = prod["stock"]
                else
                  prod2 = 0
                end
                sorted_suppliers.push([seller.name, prod["price"], supplier.time, prod2])
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
  #puts sorted_suppliers
  return sorted_suppliers # ojo que podría retornar un arreglo vacío
end

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

def produce_and_supplying2 (sku, qty, fecha_max)

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
  end

  #Ir y producir stock, máximo 5000 por ciclo. **Llega a Recepción y si está lleno , llega a pulmón.
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

  # Nosotros no hacemos move_to_despacho(qty, sku)

  puts("#{longest_time}")
  #retorno fecha en que todo lo fabricado debería llegar
  return longest_time
end

def move_to_intermedio(qty, sku)
  remaining = qty
  # Indica si es necesario o no llegar al pulmon a revisar
  search_pulmon = false
  while remaining > 0 do
    # Buscar en recepcion
    if !search_pulmon
      data = "GET" + Rails.configuration.recepcion_id + sku #GETalmacenIdsku
      url = "https://integracion-2017-prod.herokuapp.com/bodega/stock?almacenId=" + Rails.configuration.recepcion_id + "&sku=" + sku
      loop do
        products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
        break if products.code == 200
        sleep(60) if products.code == 429
      end
      search_pulmon = true if products.parse.empty?
    else
      # Buscar en pulmon
      data = "GET" + Rails.configuration.pulmon_id + sku #GETalmacenIdsku
      url = "https://integracion-2017-prod.herokuapp.com/bodega/stock?almacenId=" + Rails.configuration.pulmon_id + "&sku=" + sku
      loop do
        products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
        break if products.code == 200
        sleep(60) if products.code == 429
      end
    end

    products.parse.each do |product|
      data = "POST" + product["_id"] + Rails.configuration.intermedio_id_1 #POSTproductoIdalmacenId
      url = "https://integracion-2017-prod.herokuapp.com/bodega/moveStock"
      move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(url, json: { productoId: product["_id"], almacenId: Rails.configuration.intermedio_id_1 })
      if move.code == 200
        remaining -= 1
      end
    end
  end
end



data = "GET"
response = ""
loop do
  response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
  break if response.code == 200
  sleep(60) if response.code == 429
end
@almacenes = JSON.parse response.to_s

scheduler = Rufus::Scheduler.new
por_producir = Array.new

scheduler.every '5h', :first_at => Time.now + 18000 do
  # rake "mails:monthly_report_mail"
  Product.all.each do |prod|
    stock = get_stock_by_sku(prod)
    puts("\nSKU: #{prod.sku}, #{stock}")
    if stock < 500
      cantidad_i = prod.lot
      if prod.lot < 500
        while cantidad_i < 500
          cantidad_i += prod.lot
        end
      end
      por_producir.push([cantidad_i, prod.sku])
    else
      puts("Queda #{prod.name}. No hacer nada")
    end
  end
  # Ahora procedemos pedir efectivamente lo que pusimos en nuestra lista
  lista_retiro = Array.new
  por_producir.each do |pedido|
    lista_retiro.push([produce_and_supplying2(pedido[1], pedido[0], (Time.now + 7200).to_f*1000), pedido[0], pedido[1]])
  end
  #ordenar según tiempos retiro
  lista_retiro.sort!{|a,b| a[0] <=> b[0]}

  lista_retiro.each do |por_retirar|
    while por_retirar[0] < Time.now
      sleep(300) # vuelvo a preguntar en 5 minutos
    end
    move_to_intermedio(por_retirar[1], por_retirar[2]) # (cantidad, sku)
  end
end
