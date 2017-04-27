class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_exception
    rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique_exception
    rescue_from ActiveRecord::RecordInvalid,with: :record_invalid_exception
    rescue_from ActionController::RoutingError, with: :route_exception

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


end