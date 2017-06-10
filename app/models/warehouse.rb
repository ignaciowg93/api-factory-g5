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



    def consultar_sku(sku)
      stock = get_stock_producto(sku)
      JSON.parse({:stock => stock , :sku => sku }.to_json)
    end

    def get_stock_producto(sku)
      #TODO
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


    def get_almacenes()
      data = "GET"
      response = ""
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        break if response.code == 200
        sleep(60) if response.code == 429
      end
      almacenes = JSON.parse response.to_s
    end



    def move_product(sku , qty)
      #TODO mueve el producto con el ksu y la cantdad a la bodega de despacho.
    end


    def dispatch_order(order_id, sku, qty, price)
      #TODO despacha la cantidad solicitada. 
    end


end
