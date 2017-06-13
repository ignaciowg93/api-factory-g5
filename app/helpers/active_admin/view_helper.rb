
module ActiveAdmin::ViewHelper
    require 'http'
    require 'digest'
    base_route = "https://integracion-2017-dev.herokuapp.com/oc/"

    def get_warehouse
        stock_final = 0
        data = "GET"
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        almacenesP = JSON.parse response.to_s
        return almacenesP
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
