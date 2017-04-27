class PurchaseOrdersController < ApplicationController


    def new
        @purchase_order = PurchaseOrder.new
    end

##BUYING
    def accepted
        #The provider accepts a PO that we created. 
        begin
            @purchase_order = set_purchase_order
            @purchase_order.status = "accepted"
            if @purchase_order.save!
                render json: {ok: "Resolución recibida exitosamente" }, status: 201
            else
                render json: {error: "No se pudo enviar resolución"}, status: 500
            end
        rescue ActiveRecord::RecordNotFound 
            render json:{error: "Id no asociado a OC por resolver"}, status: 404
        end

    end
    def rejected
         begin
            @purchase_order = set_purchase_order
            @purchase_order.status = "rejected"
            if @purchase_order.save!
                render json: {ok: "Resolución recibida exitosamente" }, status: 201
            else
                render json: {error: "No se pudo enviar resolución"}, status: 500
            end
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
        @purchase_order = PurchaseOrder.new(purchase_order_params)  
        @purchase_order.poid = params[:id]  
        @purchase_order.save
        render json:{ok: "OC recibida exitosamente"} , status:201
      rescue ActiveRecord::RecordInvalid
        render json:{error: "no se pudo enviar OC"}, status: 500
      end
    end
    
    
private 

    def purchase_order_params
        params.permit( :purchase_order,:id ,:payment_method , :payment_option, :rejection, :poid)
    end

    def set_purchase_order
        @purchase_order = PurchaseOrder.find_by(poid: params[:id])
    end

    #TODO
    #When a Oc is creaed we have to check its existance in the OC server. If not return a 404.
end
