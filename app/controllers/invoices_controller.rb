class InvoicesController < ApplicationController



    def new
        @invoice = Invoice.new
    end
###BUYING

    def receive
        # We receive the invoice ID from the provider.  Recibimos la cuenta a la cual tenemos que transferir.
        begin
            @invoice = Invoice.new(invoice_params)
            @invoice.invoiceid = params[:id]
            if @invoice.save
                @invoice.save!
                render json: {ok: "notificación recibida exitosamente"} , status: 201    
            else
                render json: {error: "No se pudo enviar resolución"}, status: 500    
            end
         rescue ActiveRecord::RecordNotFound 
            render json:{error: "Id no asociado a OC por resolver"}, status: 404
         #rescue ActionController::ParameterMissing
          #   render json:{error:"Falta algún parámetro"}, status: 422
         end
    end


###SELLING
    def create
    end
    

    def accepted
        #Change the status of a Invoice in the invoice system.
        #have to validate de id. We generated this Invoice
    end

    def rejected
        #Change the status of an Invoice in the system.
    end

    def paid
        #change the status of an Invoice inthe system. Check for the transaction.
    end

private

    def invoice_params
        params.require(:invoice).permit(:id,:rejected,:accepted, :paid,:delivered, :account,:date,:proveedor,:cliente,:price, :tax, :total_price , :purchase_order_id,:invoiceid )
    end

    def set_invoice
        @invoice = Invoice.find(params[:invoiceid])
    end
end
