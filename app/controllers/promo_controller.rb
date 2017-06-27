class PromoController < ApplicationController

    def revisar_codigo
        puts 'entre'
        sku = params["sku"]
        codigo = params["code"]
        promo = Promo.find_by codigo: codigo
        if promo != nil
            fin = promo.fin
            if ((Time.zone.now - fin)<0)
                render json: {:existe =>true, :precio=>promo.precio}, status: 200
            else
                render json: {:existe=>false}, status: 401
            end
        else 
            render json: {:existe=>false}, status: 404
        end
    end
end