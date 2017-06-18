require "http"
require 'digest'

class InteractionController < ApplicationController
  before_action :get_almacenes
  # Methods for manual implementation from dashboard



  def produce

    sku = params[:sku]
    puts "sku= #{sku}"
    quantity = params[:quantity].to_i
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
          stocks = Warehouse.get_stocks
          if supply.requierment > stocks[supply.sku]
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
        mandar_a_producir(lot,product, sku, lot)
      end
    else
      puts "no procesado"
      # Producir todo
      mandar_a_producir(to_produce, product, sku, lot)
    end
  end

  def mandar_a_producir(quantity, product, sku, lot)
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
