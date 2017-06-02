require "http"
require 'digest'
require 'rubygems'
# require 'base64'
# require 'cgi'
require 'hmac-sha1'
require 'openssl'
require 'base64'
require 'open-uri'
require 'rest-client'
# require 'net/http'
# require 'uri'
# require 'typhoeus'

class ProductController < ApplicationController
    almacen_base_url = "https://integracion-2017-prod.herokuapp.com/bodega/almacenes"
    stock_productos = Hash.new(0)

    def index
        @products = Product.all
        @stock = find_qt_by_sku
        arreglo = Array.new
        @products.each do |p|
            temp = {:sku => p.sku , :name => p.name , :price=> p.price , :stock=> @stock[p.sku]}
            p(temp)
            arreglo.push(temp)
        end

        render :json => arreglo
    end

    def prices
        @products = Product.all
        @stock = find_qt_by_sku
        arreglo = Array.new
        @products.each do |p|
          temp = {:sku => p.sku , :precio=> p.sell_price , :stock=> @stock[p.sku]}
          p(temp)
          arreglo.push(temp)
        end

        render :json => arreglo

    end

    def index_total
        @products = Product.all
        @stock = find_qt_by_sku
        arreglo = Array.new
        @products.each do |p|
            temp = {:sku => p.sku , :name => p.name , :price=> p.price , :stock=> @stock[p.sku] - p.stock_reservado}
            stock_display = @stock[p.sku] #- p.stock_reservado
            puts("Producto: #{p.name}, stock: #{stock_display}")
            p.supplies.each do |insumo|
              stock_display = @stock[insumo.sku]
              puts("\tInsumo: #{insumo.sku}, stock: #{stock_display}")
            end
        end
    end
    def find
        response = Product.consultar(params[:sku])
        render :json => response
        puts 'esta es la response:'
        puts response
    end

private
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



    def prices
        @products = Product.all
        @stock = find_qt_by_sku
        arreglo = Array.new
        @products.each do |p|
            temp = {:sku => p.sku , :price=> p.price , :stock=> @stock[p.sku] }
            p(temp)
            arreglo.push(temp)
        end

        render :json => arreglo

    end
end
