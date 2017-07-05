require "http"
require 'digest'


class ApplicationController < ActionController::Base
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_exception
    rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique_exception
    rescue_from ActiveRecord::RecordInvalid,with: :record_invalid_exception
    rescue_from ActionController::RoutingError, with: :route_exception
    before_action :get_almacenes


###Error Management
    def record_not_found_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "No se ha encotrado el recurso solicitado"}, status: :not_found
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: :not_found
        end
    end

    def record_not_unique_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "Ha presentado un error. La entidad creada entra en conflicto con otra alojada en la base de datos. Solicitud DENEGADA"}, status: 403
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 403
        end
    end

    def record_invalid_exception(exception)
        logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "El recurso es inválido."}, status: 422
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 422
        end
    end

    def route_exception(exception)
         logger.info("#{exception.class}: " + exception.message)
        if Rails.env.production?
            render json: {error: "Ruta inválida!"}, status: 500
        else
            render json: { message: exception, backtrace: exception.backtrace }, status: 500
        end
    end

     unless Rails.application.config.consider_all_requests_local
        rescue_from ActionController::RoutingError, with: -> { render_404  }
     end

    def render_404
        respond_to do |format|
        format.json { render json: {error: "Ruta no encontrada!"}, status: 404 }
        format.all { render nothing: true, status: 404 }
        end
    end

    def production_log
      if File.exist? 'log/production.log'
        @tail = `tail -n 200 log/production.log`
      else
        @tail = 'No se encontro production.log'
      end
    end

    def development_log
      if File.exist? 'log/development.log'
        @tail = `tail -n 200 log/development.log`
      else
        @tail = 'No se encontro development.log'
      end
    end

    def check_status_update_log
      if File.exist? 'log/check_status_update.log'
        @tail = `tail -n 200 log/check_status_update.log`
      else
        @tail = 'No se encontro check_status_update.log'
      end
    end

    def promo_log
      if File.exist? 'log/promo.log'
        @tail = `tail -n 200 log/promo.log`
      else
        @tail = 'No se encontro promo.log'
      end
    end


    private

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

    def get_almacenes
      data = "GET"
      response = ""
      loop do
        response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
        break if response.code == 200
        sleep(60) if response.code == 429
      end
      @almacenes = JSON.parse response.to_s
    end

    def generate_header(data)
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
      signature = Base64.encode64(hmac).chomp
      auth_header = "INTEGRACION grupo5:" + signature
      auth_header
    end
end
