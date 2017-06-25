# == Schema Information
#
# Table name: products
#
#  id              :integer          not null, primary key
#  sku             :string
#  name            :string
#  price           :decimal(64, 12)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  warehouse_id    :integer
#  processed       :integer
#  lot             :integer
#  ingredients     :integer
#  dependent       :integer
#  time            :decimal(, )
#  sell_price      :integer
#  stock_reservado :integer
#

require 'rubygems'
require "http"
require 'base64'
require 'cgi'
require 'hmac-sha1'
require 'openssl'
require 'base64'
require 'digest'
require 'open-uri'
require 'rest-client'
require 'net/http'
require 'uri'
require 'typhoeus'
require 'bunny'

class Product < ApplicationRecord

	@secret = "W1gCjv8gpoE4JnR"
    @url_dev = "https://integracion-2017-dev.herokuapp.com"
    has_many :supplies

    #TODO Referencia a otros productos ( has_many or null).
    #TODO REferencia a clientes y proveedores.( Has_mny o null).
    #JOINT tabla de productos con productos.
    # Usar el trough.

	def self.encrypt(texto)
		key = texto

		#if Rails.env.production?
			data = 'ZC$&k:.gFIZ&pyp'   #PENDIENTE esto cambia segun dev o prod o no ?
			OpenSSL::HMAC.digest('SHA1',data,key)
			Base64.strict_encode64 OpenSSL::HMAC.digest('SHA1',data,key)
		#else
		#	data = 'WqhY79mm3N4ph6'   #PENDIENTE esto cambia segun dev o prod o no ?
		#	OpenSSL::HMAC.digest('SHA1',data,key)
		#	Base64.strict_encode64 OpenSSL::HMAC.digest('SHA1',data,key)
		#end
	end

	def self.crear_string(data)
		string_hash = "INTEGRACION grupo5:"
		header_agregar = string_hash+encrypt(data)
	end


	def self.getAuth()
		data = "GET"
		hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @secret.encode("ASCII"), data.encode("ASCII"))
		signature = Base64.encode64(hmac).chomp
		auth_header = "INTEGRACION grupo5:" + signature
		puts 'auth header:'
		puts auth_header
	end


    def self.getAlmacenes () #entrega informacion sobre los almacenes de la bodega solicitada
    	secret = "W1gCjv8gpoE4JnR" # desarrollo
		#Mandar a la bodega. Get sku de stock.
		data = "GET"
		hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret.encode("ASCII"), data.encode("ASCII"))
		signature = Base64.encode64(hmac).chomp
		auth_header = "INTEGRACION grupo5:" + signature
		# pedimos el arreglo de almacenes
		almacenes = HTTP.auth(auth_header).headers(:accept => "application/json").get("https://integracion-2017-dev.herokuapp.com/bodega/almacenes")
		puts 'resultado:'
		puts almacenes
		return almacenes
	end

    def self.getSkusWithStock(almacenId)
    	header = crear_string("GET" + almacenId)

    	#if Rails.env.production?
    		buffer = open(@url_dev + '/bodega/skusWithStock?almacenId='+almacenId , "Content-Type"=>"application/json", "Authorization" => header).read
    	#else
    	#	buffer = open('http://integracion-2016-dev.herokuapp.com/bodega/skusWithStock?almacenId='+almacenId , "Content-Type"=>"application/json", "Authorization" => header).read
    	#end

    	resultado = JSON.parse(buffer)

    end


    def self.getStock(almacenId, sku) #devuelve todos los productos de un sku que estan en un almacen
    	header = crear_string("GET"+almacenId.to_s+sku.to_s)

    	#if Rails.env.production?
    		buffer = open(@url_dev + '/bodega/stock?almacenId='+almacenId.to_s+"&sku="+sku.to_s, "Content-Type"=>"application/json", "Authorization" => header).read
    	#else
    	#	buffer = open('http://integracion-2016-dev.herokuapp.com/bodega/stock?almacenId='+almacenId+"&sku="+sku, "Content-Type"=>"application/json", "Authorization" => header).read
    	#end

    	resultado = JSON.parse(buffer)


    end




    def self.consultar(sku_request)

	     #sku_request = params[:sku] o por parametro de metodo
    	#stock = getStockProducto(sku_request)
		stock = get_stock_by_sku(sku_request)
		puts 'este es stock'
		puts stock
    	JSON.parse({:stock => stock, :sku => sku_request}.to_json)
    end

	def get_stock_by_sku(sku)
        stock_final = 0
        @secret = "W1gCjv8gpoE4JnR" # desarrollo
        bodega_sist = "https://integracion-2017-dev.herokuapp.com/bodega/" # desarrollo
        #Mandar a la bodega. Get sku de stock.
        data = "GET"
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @secret.encode("ASCII"), data.encode("ASCII"))
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

    def self.getStockProducto(sku_request)
    	stock = 0
    	almacenes = getAlmacenes()
		puts 'en StockProducto, almacenes:'
		puts almacenes
		puts 'aa'
    	almacenes.parse.each do |almacen|
			puts 'entre al parse'
    		if almacen['despacho'] == false
    			todos_los_skus = getSkusWithStock(almacen['_id'])
    			todos_los_skus.each do |sku|
    				if (sku['_id']== sku_request)
    					stock+=sku['total']
    				end
    			end
    		end

    	end
    	stock
    end

		def self.revisar_ofertas()
			STDOUT.sync = true
			conn = Bunny.new("amqp://hwlepmrs:uPDTlJqmGIB95x7jdafvpBMBb-pK7PPV@fish.rmq.cloudamqp.com/hwlepmrs")
			conn.start

			ch = conn.create_channel
			q  = ch.queue("ofertas", :auto_delete => true)
			x  = ch.default_exchange


			q.subscribe do |delivery_info, metadata, payload|
			  puts payload
			  payload = JSON.parse(payload)
			  #msg_tp = "MENSAJE DE PRUEBA DESDE API"
			  if !payload["publicar"]
					product = (Product.find_by sku: payload["sku"]).name
			    to_publi = "Ahora+nuestro+#{product}+a+tan+solo+$#{payload["precio"]}!"
			    publi = HTTP.post("https://graph.facebook.com/307193066399367/feed?message=#{to_publi}&access_token=EAADxlJnEikwBAMhlvuWmPkZAX6kWLDhZACdjf7O1QKfzHwd3UBMqZCD76yObHWGZCAhvWhGOG9hHe9Bz4nu4m8hspeCkt7I5zWmXm0IPzTmmiZAWNkpkSSLtyopmv3RjGEPk24ZCg6rD8kpO76oen3ZCkWhEj391bHXVXXvnxNvF8OcgVTtLzep")
			    puts publi
			  end
			  sleep(5)

			end
			sleep 1.0
			conn.close
		end

end
