class InvoicesController < ApplicationController


    def new
        @invoice = Invoice.new
    end
###BUYING

    def receive
        # We receive the invoice ID from the provider.  Recibimos la cuenta a la cual tenemos que transferir.
        @invoice = Invoice.create!(invoice_params)
        render json: {ok: "notificación recibida exitosamente"} , status: 201
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
        params.permit(:rejected,:accepted, :paid, :invoiceid,:delivered, :account )
    end

    def set_invoice
        @invoice = Invoice.find(params[:invoiceid])
    end
end
