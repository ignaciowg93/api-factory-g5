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

    def self.to_despacho_and_delivery(sku, qty, almacen_recepcion, ordenId, precio, canal)
      products = ""
      orden = PurchaseOrder.find_by(_id: ordenId)
      remaining = qty - orden.delivered_qt
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
              data = "POST#{product["_id"]}#{almacen_recepcion}"
              loop do
                deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").post(route, json: { productoId: product["_id"], almacenId: almacen_recepcion, oc: ordenId, precio: precio})
                break if deliver.code == 200
                sleep(60) if deliver.code == 429
                sleep(15)
              end
            elsif canal == "b2c" || canal == "ftp"
              # FIXME: unauthorized
              route = "#{Rails.configuration.base_route_bodega}stock"
              data = "DELETE#{product["_id"]}Distribuidor#{precio}"
              loop do
                deliver = HTTP.auth(generate_header(data)).headers(:accept => "application/json").delete(route, json: { productoId: product["_id"], oc: ordenId, direccion: "distribuidor", precio: precio})
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

    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
    end


end
