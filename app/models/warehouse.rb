# == Schema Information
#
# Table name: warehouses
#
#  id         :integer          not null, primary key
#  type       :integer
#  capacity   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'http'
require 'digest'

class Warehouse < ApplicationRecord
  has_many :products

  def self.consultar_sku(product)
    stock = get_stock_by_sku(product)
    JSON.parse({ stock: stock, sku: product.sku }.to_json)
  end

  def self.get_stock_by_sku(prod) # FIXME: producto en vez de sku
    puts 'llegue al metodo'
    puts prod
    sku = prod.sku
    puts sku
    stock = 0
    response = ''
    @almacenes = get_almacenes
    @almacenes.each do |almacen|
      # No busca en despacho
      next if almacen['despacho']
      data = "GET#{almacen['_id']}"
      loop do
        response = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + 'skusWithStock?almacenId=' + almacen['_id'])
        break if response.code == 200
        sleep(60) if response.code == 429
        sleep(15)
      end
      products = JSON.parse response.to_s
      next if products.empty?
      products.each do |product|
        # Sku viene en id de producto
        stock += product['total'] if product['_id'] == sku
      end
    end
    stock - prod.stock_reservado > 0 ? (stock - prod.stock_reservado) : 0
  end

  def self.get_stocks
    stocks = Hash.new(0)
    response = ''
    @almacenes = get_almacenes
    @almacenes.each do |almacen|
      # No busca en despacho
      next if almacen['despacho']
      data = "GET#{almacen['_id']}"
      loop do
        response = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + 'skusWithStock?almacenId=' + almacen['_id'])
        break if response.code == 200
        sleep(60) if response.code == 429
        sleep(15)
      end
      products = JSON.parse response.to_s
      products.each do |product|
        # product["_id"] es el sku del producto
        # FIXME: restar unidades reservadas
        stocks[product['_id']] += product['total']
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

  def self.get_almacenes
    data = 'GET'
    response = ''
    loop do
      response = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + 'almacenes')
      break if response.code == 200
      sleep(60) if response.code == 429
      sleep(15)
    end
    almacenes = JSON.parse response.to_s
  end

  def self.to_despacho_and_delivery(poid)
    products = ''
    orden = PurchaseOrder.find_by(_id: poid)
    return unless orden
    sku = orden.sku
    precio = orden.unit_price
    canal = orden.channel
    direccion = orden.direccion
    remaining = orden.amount - orden.delivered_qt
    prod = Product.find_by(sku: sku)
    @almacenes = get_almacenes

    while remaining > 0
      @almacenes.each do |almacen|
        next if almacen['despacho']
        limit = (remaining if remaining < 200) || 200
        data = "GET#{almacen['_id']}#{sku}" # GETalmacenIdsku
        route = "#{Rails.configuration.base_route_bodega}stock?almacenId=#{almacen['_id']}&sku=#{sku}&limit=#{limit}"
        loop do
          products = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(route)
          break if products.code == 200
          sleep(60) if products.code == 429
          sleep(15)
        end
        products.parse.each do |product|
          # Move product to despacho
          data = "POST#{product['_id']}#{Rails.configuration.despacho_id}" # POSTproductoIdalmacenId
          route = "#{Rails.configuration.base_route_bodega}moveStock"
          move = ''
          loop do
            move = HTTP.auth(generate_header(data)).headers(accept: 'application/json').post(route, json: { productoId: product['_id'], almacenId: Rails.configuration.despacho_id })
            break if move.code == 200
            sleep(60) if move.code == 429
            sleep(15)
          end

          # Product delivery
          if canal == 'b2b'
            route = "#{Rails.configuration.base_route_bodega}moveStockBodega"
            data = "POST#{product['_id']}#{direccion}"
            loop do
              deliver = HTTP.auth(generate_header(data)).headers(accept: 'application/json').post(route, json: { productoId: product['_id'], almacenId: direccion, oc: poid, precio: precio })
              break if deliver.code == 200
              sleep(60) if deliver.code == 429
              sleep(15)
            end
          elsif canal == 'b2c' || canal == 'ftp'
            route = "#{Rails.configuration.base_route_bodega}stock"
            data = "DELETE#{product['_id']}#{direccion}#{precio}#{poid}"
            loop do
              deliver = HTTP.auth(generate_header(data)).headers(accept: 'application/json').delete(route, json: { productoId: product['_id'], oc: poid, direccion: direccion, precio: precio })
              puts deliver.body
              break if deliver.code == 200
              sleep(60) if deliver.code == 429
              sleep(15)
            end
          end

          remaining -= 1
          # Liberar unidades reservadas
          # Aumentar en unidades despachadas
          prod.stock_reservado -= 1
          prod.save
          orden.delivered_qt += 1
          orden.save
        end
        break if remaining == 0
      end
    end
    # Orden de compra se cambia a finalizada en la db
    orden.status = 'finalizada'
    return true if orden.save!
  end

  def self.vaciar_almacenes
    # revisar el almacen intermedio principal y ver su capacidad
    almacenes_req = HTTP.auth(generate_header('GET')).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + 'almacenes')
    almacenes = almacenes_req.parse
    capacidad_disponible1 = 0
    capacidad_disponible2 = 0
    # quizas conviene cortar el loop, aunque no es mucha pega
    almacenes.each do |almacen|
      if almacen['_id'] == Rails.configuration.intermedio_id_1
        capacidad_disponible1 = almacen['totalSpace'] - almacen['usedSpace']
      elsif almacen['_id'] == Rails.configuration.intermedio_id_2
        capacidad_disponible2 = almacen['totalSpace'] - almacen['usedSpace']
      end
    end
    puts "capacidad disponible alm1: #{capacidad_disponible1}, alm2: #{capacidad_disponible2}"
    # mover skus en pulmon
    data = "GET#{Rails.configuration.pulmon_id}"
    skus = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=#{Rails.configuration.pulmon_id}")
    puts skus.parse
    # aplicar mover(sku_qty)
    skus.parse.each do |alm_prod|
      # mover cada sku
      mover_prods(alm_prod['_id'], alm_prod['total'], Rails.configuration.pulmon_id, capacidad_disponible1, capacidad_disponible2)
    end

    almacenes.each do |almacen|
      if almacen['_id'] == Rails.configuration.intermedio_id_1
        capacidad_disponible1 = almacen['totalSpace'] - almacen['usedSpace']
      elsif almacen['_id'] == Rails.configuration.intermedio_id_2
        capacidad_disponible2 = almacen['totalSpace'] - almacen['usedSpace']
      end
    end
    # mover skus en recepcion
    data = "GET#{Rails.configuration.recepcion_id}"
    skus = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=#{Rails.configuration.recepcion_id}")
    puts skus.parse
    # aplicar mover(sku_qty)
    skus.parse.each do |alm_prod|
      # mover cada sku
      mover_prods(alm_prod['_id'], alm_prod['total'], Rails.configuration.recepcion_id, capacidad_disponible1, capacidad_disponible2)
    end
  end

  def self.mover_prods(sku, remaining, almacen_id, capacidad1, capacidad2)
    puts 'metodo mover_prods (linea 177)'
    data = 'GET' + almacen_id + sku
    url = "#{Rails.configuration.base_route_bodega}stock?almacenId=#{almacen_id}&sku=#{sku}"
    capacidad_almacen_recibiendo = capacidad1
    alm_id = Rails.configuration.intermedio_id_1
    products = ''
    while remaining > 0
      puts('otro ciclo')
      3.times do
        products = HTTP.auth(generate_header(data)).headers(accept: 'application/json').get(url)
        puts(products.code)
        break if products.code == 200
        sleep(60)
      end
      puts "\nlinea 191\n"
      next unless products.code == 200 && !products.parse.empty?
      products.parse.each do |product|
        next unless remaining > 0
        if capacidad_almacen_recibiendo <= 0
          capacidad_almacen_recibiendo = capacidad2
          alm_id = Rails.configuration.intermedio_id_2
        end
        data2 = 'POST' + product['_id'] + alm_id
        url2 = "#{Rails.configuration.base_route_bodega}moveStock"
        move = HTTP.auth(generate_header(data2)).headers(accept: 'application/json').post(url2, json: { productoId: product['_id'], almacenId: alm_id })

        if move.code == 200
          puts "move 200, quedan: #{remaining - 1}"
          remaining -= 1
          capacidad_almacen_recibiendo -= 1
        else
          sleep(10)
          puts("#{move.code}, #{move}")
        end
      end
    end
  end

  def generate_header(data)
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode('ASCII'), data.encode('ASCII'))
    signature = Base64.encode64(hmac).chomp
    auth_header = 'INTEGRACION grupo5:' + signature
    auth_header
  end

  def dispatch_order(order_id, sku, qty, price)
    # TODO: despacha la cantidad solicitada.
  end



  # -------------  ** ----------
  #No procesados
  def self.revisar_maiz()
    sku = '3'
    revisar(sku)
  end

  def self.revisar_leche()
    sku = '7'
    revisar(sku)
  end

  def self.revisar_carne()
    sku = '9'
    revisar(sku)
  end

  def self.revisar_avena()
    sku = '15'
    revisar(sku)
  end

  def self.revisar_azucar()
    sku = '25'
    revisar(sku)
  end
  # -------------  ** ----------

  # -------------  ** ----------
  # Procesados, como no se manda a producir automaticamente se

  def self.revisar_margarina()
    sku = '11'
    revisar(sku)
  end

 def self.revisar_yogur()
    sku = '5'
    revisar(sku)
  end

  def self.cereal_arroz()
    sku = '17'
    revisar(sku)
  end

  def self.mantequilla()
    sku = '22'
    revisar(sku)
  end

  def self.harina_integral()
    sku = '52'
    revisar(sku)
  end

  def self.hamburguesas_pollo()
    sku = '56'
    revisar(sku)
  end

  # -------------  ** ----------


  # ------------- ** --------------
  def self.revisar(sku)
    producto = (Product.find_by(sku: sku))
    # puts 'voy a llamar ge stock by sku con: #{producto.sku}'
    stock = get_stock_by_sku(producto) #Obtengo el stock actual de maiz
    stock_minimo = 1000 #Stock minimo que debe haber de la materia prima
    # puts 'entrando al stock'
    puts stock
    if stock <= stock_minimo #Si tenemos menos stock del que deberia haber
      dif = stock_minimo - stock
      #lotes = dif/60 #Esto da un numero int (3/2 = 1)
      #Esto no es necesario porque lo hace dentro del produce
      #puts "deberia mandar a prod"
      Warehouse.produce(sku, dif) #Se manda a hacer Dif
    end
  end




  ### -------------- ** --------------------
  #Estos son los metodos de Interaction, movi Produce,  mandar_a_producir, move_to_despacho y get_almacenes
  def self.produce(sku,quantity)

    # sku = params[sku]
    #puts "sku= #{sku}"
    # quantity = params[:quantity].to_i
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
          if supply.requierment > stocks[supply.sku]
            remain = supply.requierment - stocks[supply.sku]
            # FIXME: Solo se produce si hay stock
            # # Abastecerse del resto
            # abastecimiento_mp(sku, supply.sku, remain, fecha, Rails.configuration.recepcion_id)
            render json: {error: "Faltan #{remain} unidades de sku #{supply.sku}"}, status: 400
            puts "Faltan #{remain} unidades de sku #{supply.sku}"
            return
          end
        end
        # Mover unidades a almacen de despacho
        my_supplies.each do |supply|
          puts "1- muevo a despacho"
          Warehouse.move_to_despacho(supply.requierment, supply.sku)
        end
        # Producir un solo lote
        Warehouse.mandar_a_producir(lot,product, sku)
      end
    else
      puts "no procesado"
      # Producir todo
      Warehouse.mandar_a_producir(to_produce, product, sku)
    end
  end

  def self.mandar_a_producir(quantity, product, sku)
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
        # FIXME guardar hora de entrega
        if production_order.code == 200
          Rails.logger.debug "Es en mandar a producir"
          production_order_to_save = ProductionOrder.new
          production_order_to_save.sku = sku
          production_order_to_save.amount =  to_produce
          production_order_to_save.est_date = production_order.parse["disponible"]
          production_order.save!
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
          Rails.logger.debug ("error en p_order: #{a}")
          puts("error en p_order: #{a}")
        end
      end
    end
  end

  def self.move_to_despacho(qty, sku)
    products = ""
    remaining = qty
    #@almacenes = get_almacenes
    while remaining > 0 do
      @almacenes.each do |almacen|
        next if almacen["despacho"]
        limit = (remaining if remaining < 200) || 200
        puts "limit es #{limit}"
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
          puts "ahora quedan #{remaining}"
        end
        break if remaining == 0
      end
    end
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
end
