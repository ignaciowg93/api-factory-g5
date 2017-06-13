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
        @stock = Warehouse.get_stocks
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
        @stock = Warehouse.get_stocks
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
        @stock = Warehouse.get_stocks
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




end
