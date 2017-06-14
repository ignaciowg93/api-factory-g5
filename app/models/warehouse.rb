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
require "http"
require 'digest'

class Warehouse < ApplicationRecord
    has_many :products


    def self.consultar_sku(product)
      stock = get_stock_by_sku(product)
      JSON.parse({stock: stock , sku: product.sku }.to_json)
    end

    def self.get_stock_by_sku(prod) # FIXME: producto en vez de sku
      sku = prod.sku
      stock = 0
      response = ""
      @almacenes = get_almacenes
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

    def self.get_stocks
      stocks = Hash.new(0)
      response = ""
      @almacenes = get_almacenes
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

    def self.get_almacenes
      data = "GET"
      response = ""
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        break if response.code == 200
        sleep(60) if response.code == 429
        sleep(15)
      end
      almacenes = JSON.parse response.to_s
    end

    def self.to_despacho_and_delivery(poid)
      products = ""
      orden = PurchaseOrder.find_by(_id: poid)
      return unless orden
      sku = orden.sku
      precio = orden.unit_price
      canal = orden.channel
      direccion = orden.direccion
      remaining = orden.amount - orden.delivered_qt
      prod = Product.find_by(sku: sku)
      @almacenes = get_almacenes

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
            # Move product to despacho
            data = "POST#{product["_id"]}#{Rails.configuration.despacho_id}" #POSTproductoIdalmacenId
            route = "#{Rails.configuration.base_route_bodega}moveStock"
            move = ""
            loop do
              move = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: Rails.configuration.despacho_id })
              break if move.code == 200
              sleep(60) if move.code == 429
              sleep(15)
            end

            # Product delivery
            if canal == "b2b"
              route = "#{Rails.configuration.base_route_bodega}moveStockBodega"
              data = "POST#{product["_id"]}#{direccion}"
              loop do
                deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: direccion, oc: poid, precio: precio})
                break if deliver.code == 200
                sleep(60) if deliver.code == 429
                sleep(15)
              end
            elsif canal == "b2c" || canal == "ftp"
              route = "#{Rails.configuration.base_route_bodega}stock"
              data = "DELETE#{product["_id"]}#{direccion}#{precio}#{poid}"
              loop do
                deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").delete(route, json: { productoId: product["_id"], oc: poid, direccion: direccion, precio: precio})
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
        end
      end
      # Orden de compra se cambia a finalizada en la db
      orden.status = 'finalizada'
      return true if orden.save!
    end


    def self.vaciar_almacenes()
      # revisar el almacen intermedio principal y ver su capacidad
      almacenes_req = HTTP.auth(generate_header("GET")).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + 'almacenes')
      almacenes = almacenes_req.parse
      capacidad_disponible1 = 0
      capacidad_disponible2 = 0
      # quizas conviene cortar el loop, aunque no es mucha pega
      almacenes.each do |almacen|
        if almacen["_id"] == Rails.configuration.intermedio_id_1
          capacidad_disponible1 = almacen["totalSpace"] - almacen["usedSpace"]
        elsif almacen["_id"] == Rails.configuration.intermedio_id_2
          capacidad_disponible2 = almacen["totalSpace"] - almacen["usedSpace"]
        end
      end
      puts "capacidad disponible alm1: #{capacidad_disponible1}, alm2: #{capacidad_disponible2}"
      # mover skus en pulmon
      data = "GET#{Rails.configuration.pulmon_id}"
      skus = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=#{Rails.configuration.pulmon_id}")
      puts skus.parse
      # aplicar mover(sku_qty)
      skus.parse.each do |alm_prod|
        # mover cada sku
        mover_prods(alm_prod["_id"], alm_prod["total"], Rails.configuration.pulmon_id, capacidad_disponible1, capacidad_disponible2)
      end

      almacenes.each do |almacen|
        if almacen["_id"] == Rails.configuration.intermedio_id_1
          capacidad_disponible1 = almacen["totalSpace"] - almacen["usedSpace"]
        elsif almacen["_id"] == Rails.configuration.intermedio_id_2
          capacidad_disponible2 = almacen["totalSpace"] - almacen["usedSpace"]
        end
      end
      # mover skus en recepcion
      data = "GET#{Rails.configuration.recepcion_id}"
      skus = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=#{Rails.configuration.recepcion_id}")
      puts skus.parse
      # aplicar mover(sku_qty)
      skus.parse.each do |alm_prod|
        # mover cada sku
        mover_prods(alm_prod["_id"], alm_prod["total"], Rails.configuration.recepcion_id, capacidad_disponible1, capacidad_disponible2)
      end

    end

    def self.mover_prods(sku, remaining, almacen_id, capacidad1, capacidad2)
      puts "metodo mover_prods (linea 177)"
      data = "GET" + almacen_id + sku
      url = "#{Rails.configuration.base_route_bodega}stock?almacenId=#{almacen_id}&sku=#{sku}"
      capacidad_almacen_recibiendo = capacidad1
      alm_id = Rails.configuration.intermedio_id_1
      products = ""
      while remaining > 0
        puts("otro ciclo")
        3.times do
          products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(url)
          puts(products.code)
          if products.code == 200
            break
          end
        sleep(40)
        end
        puts "\nlinea 191\n"
        if products.code == 200 && !products.parse.empty?
          products.parse.each do |product|
            if remaining > 0
              if capacidad_almacen_recibiendo <= 0
                capacidad_almacen_recibiendo = capacidad2
                alm_id = Rails.configuration.intermedio_id_2
              end
              data2 = "POST" + product["_id"] + alm_id
              url2 = "#{Rails.configuration.base_route_bodega}moveStock"
              move = HTTP.auth(generate_header(data2)).headers(:accept => "application/json").post(url2, json: { productoId: product["_id"], almacenId: alm_id })

              if move.code == 200
        	       puts "move 200, quedan: #{remaining - 1}"
                 remaining -= 1
                 capacidad_almacen_recibiendo -= 1
              else
              	sleep(10)
              	puts("#{move.code}, #{move.to_s}")
              end
            end
          end
        end
      end
    end

    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
    end

    def dispatch_order(order_id, sku, qty, price)
      #TODO despacha la cantidad solicitada.
    end


end
