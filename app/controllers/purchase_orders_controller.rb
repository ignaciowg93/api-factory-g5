class PurchaseOrdersController < ApplicationController

    def new
        @purchase_order=PurchaseOrder.new
    end

    def create
      begin
        @purchase_order = PurchaseOrder.create!(purchase_order_params)
        render json:{ok: "OC recibida exitosamente"} , status:201
      rescue ActiveRecord::RecordInvalid
        render json:{error: "no se pudo enviar OC"}, status: 500
      end
    end




private 

    def purchase_order_params
        params.permit(:purchase_order, :payment_method , :payment_option)
    end

    def set_purchase_order
        @purchase_order = PurchaseOrder.find(params[:id])
    end

    #TODO
    #When a Oc is creaed we have to check its existance in the OC server. If not return a 404.
end
