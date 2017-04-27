class PurchaseOrdersController < ApplicationController


##BUYING
    def accept
        #The provider accepts a PO that we created. 
        begin
            @purchase_order = set_purchase_order
            @purchase_order.status = "accepted"
            render json: {ok: "Resolución recibida exitosamente " }, status: 201
        rescue ActiveRecord::RecordNotFound 
            render json:{error: "Id no asociado a OC por resolver"}, status: 404
        end

    end
    def reject
         begin
            @purchase_order = set_purchase_order
            @purchase_order.status = "rejected"
            render json: {ok: "Resolución recibida exitosamente" }, status: 201
        rescue ActiveRecord::RecordNotFound 
            render json:{error: "Id no asociado a OC por resolver"}, status: 404
        end
        
        # The provider rejects a PO created by us. Check its existance.
    end
   
    def create
        ## Tenemos que generarla nosotros , por lo tanto los parametros entrar desde nuestra BDD
    end
    
###SELLING
    def receive
        #we receive a PO created by someone else, for us to sell. Check if it exists in the PO system.
       begin
        @purchase_order = PurchaseOrder.create!(purchase_order_params)  
        @purchase_order.poid = params(:id)
        render json:{ok: "OC recibida exitosamente"} , status:201
      rescue ActiveRecord::RecordInvalid
        render json:{error: "no se pudo enviar OC"}, status: 500
      end
    end

private 

    def purchase_order_params
        params.permit(:purchase_order, :payment_method , :payment_option, :rejection, :poid)
    end

    def set_purchase_order
        @purchase_order = PurchaseOrder.find(params[:poid])
    end

    #TODO
    #When a Oc is creaed we have to check its existance in the OC server. If not return a 404.
end
