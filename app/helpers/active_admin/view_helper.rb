
module ActiveAdmin::ViewHelper
    require 'http'
    require 'digest'
    base_route = "https://integracion-2017-dev.herokuapp.com/oc/"


#TODO poco eficiente. arreglar chucheta. Se llama una vez no más.

    def get_stock_helper(sku)
        stock_final = 0
          # desarrollo

        bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega/" # desarrollo
        #Mandar a la bodega. Get sku de stock.
        data = "GET"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        # pedimos el arreglo de almacenes
        puts("Antes del request")
        almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get(bodega_sist + "almacenes")
        if almacenes.code == 200
            puts("code 200 en almacenes")
            almacenesP = JSON.parse almacenes.to_s
            almacenesP.each do |almacen|
                if !almacen["despacho"] && !almacen["pulmon"]
                    data += almacen["_id"]
                    products = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(bodega_sist + "skusWithStock?almacenId=" + almacen["_id"])
                    if products.code == 200
                        productsP = JSON.parse products.to_s
                        productsP.each do |product|
                            if product["_id"] == sku
                                stock_final += product["total"]
                            end
                        end
                    end
                end
            end
        end
        return stock_final
    end


    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
    end

    def find_qt_by_sku
        #PEidr los almacenes
        #Iterar sobre los almacenes
        #Cada almacen pedir lista de productos con Stock
        #Busco el sku que necesito
        #Entregar elk Total
      stock_productos = Hash.new(0)
      secret = Rails.configuration.secret
      #Mandar a la bodega. Get sku de stock.
      data = "GET"
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      # pedimos el arreglo de almacenes
      almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get("#{Rails.configuration.base_route_bodega}almacenes")
      if almacenes.code == 200
          almacenes.parse.each do |almacen|
              if(!almacen["despacho"])
                    data = "GET" + almacen["_id"]
                    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                    signature = Base64.encode64(hmac).chomp
                    auth_header = "INTEGRACION grupo5:" + signature
                    route_to_get = "#{Rails.configuration.base_route_bodega}skusWithStock?almacenId=" + almacen["_id"]
                    products_array = HTTP.auth(auth_header).headers(:accept => "application/json").get(route_to_get)
                    if products_array.code == 200
                        products_array.parse.each do |product|
                            stock_productos[product["_id"]] += product["total"]
                        end
                    end
                end
            end
        end

        return stock_productos

    end

    def get_warehouse
        stock_final = 0
        data = "GET"
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        almacenesP = JSON.parse response.to_s
        return almacenesP
    end


    def temp(hola)
        "hola"
    end
end
