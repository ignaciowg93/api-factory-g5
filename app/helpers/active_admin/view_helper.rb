

module ActiveAdmin::ViewHelper


    require 'http'
    require 'digest'
    base_route = "https://integracion-2017-dev.herokuapp.com/oc/"


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

    def find_qt_by_sku
        #PEidr los almacenes
        #Iterar sobre los almacenes
        #Cada almacen pedir lista de productos con Stock
        #Busco el sku que necesito
        #Entregar elk Total
      stock_productos = Hash.new(0)
      secret = "%hG4INNjIAYx9&0"#'W1gCjv8gpoE4JnR'
      #Mandar a la bodega. Get sku de stock.
      data = "GET"
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      # pedimos el arreglo de almacenes
      almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-prod.herokuapp.com/bodega/almacenes")
      if almacenes.code == 200
          almacenes.parse.each do |almacen|
              if(!almacen["despacho"])
                    data = "GET" + almacen["_id"]
                    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
                    signature = Base64.encode64(hmac).chomp
                    auth_header = "INTEGRACION grupo5:" + signature
                    route_to_get = "https://integracion-2017-prod.herokuapp.com/bodega/skusWithStock?almacenId=" + almacen["_id"]
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
        secret = "W1gCjv8gpoE4JnR" # desarrollo
        bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega/" # desarrollo
        #Mandar a la bodega. Get sku de stock.
        data = "GET"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
        signature = Base64.encode64(hmac).chomp
        auth_header = "INTEGRACION grupo5:" + signature
        # pedimos el arreglo de almacenes
        almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get(bodega_sist + "almacenes")
        almacenesP = JSON.parse almacenes.to_s
        return almacenesP

    end


    def temp(hola)
        "hola"
    end
end
