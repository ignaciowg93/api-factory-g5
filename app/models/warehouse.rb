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


    def self.consultar_sku(sku)
      stock = get_stock_producto(sku)
      JSON.parse({:stock => stock , :sku => sku }.to_json)
    end

    def self.get_stock_producto(sku)

      stock_final = 0
      response = ""
      almacenes = get_almacenes()
      almacenes.each do |almacen|
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
      stock_final
    end


    def self.get_almacenes()
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


## Mover el producto a la bodega despacho.
    def self.move_product(sku , qty, almacenes)
      #TODO mueve el producto con el ksu y la cantdad a la bodega de despacho.
      products = ""
      remaining = qty
      while remaining > 0 do
        almacenes.each do |almacen|
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


    def self.dispatch_and_order(sku, qty, almacen_recepcion, ordenId, precio, cantidad_despachada, almacenes)
      #TODO despacha la cantidad solicitada.
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
        almacenes.each do |almacen|
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
      if orden.save!
        return true;
      end

    end


    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Diges*t.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
    end

    def dispatch_order(order_id, sku, qty, price)
      #TODO despacha la cantidad solicitada.
    end


end
