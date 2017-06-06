class InvoicesController < ApplicationController



    def new
        @invoice = Invoice.new
    end

    def new(oc)
      @invoice = Invoice.new

      #Ahora debo buscar los datos del invoice en PO y cargar los datos en la entidad.
      if PurchaseOrder.where(poid: oc).exists?
        @invoice.po_idtemp = oc
        @invoice.save!

      else
        puts("Error en INVOICE.NEW(OC) , no existe la Po en la BDD")
      end

      @invoice

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

#Method to generate the invoice given certain parameters.
#Returns True if code 200 is received.
#Returns false if another code is received, or fails to save in DB

    def generate_boleta
      proveedor = params["id"]
      cliente = params["cliente"]
      precio_final = params["precio"]
      cantidad = params["cantidad"]
      sku = params["sku"]
      temp_invoice = HTTP.headers(:accept => "application/json").put("https://integracion-2017-prod.herokuapp.com/sii/boleta", :json => { :proveedor =>proveedor , :cliente => cliente , :total => precio_final })
      puts(temp_invoice)
      temp_result = temp_invoice.to_s
      if temp_invoice.code == 200
        temp_boleta = temp_invoice.parse
        @invoice = Invoice.new
        @invoice.proveedor = temp_boleta["proveedor"]
        @invoice.cliente = temp_boleta["cliente"]
        @invoice.price = temp_boleta["bruto"]
        @invoice.tax = temp_boleta["iva"]
        @invoice.total_price = temp_boleta["total"]
        @invoice.boleta = true
        @invoice.invoiceid = temp_boleta["_id"]
        @invoice.status = temp_boleta["estado"]
        @invoice.amount = cantidad
        @invoice.sku = sku
        if @invoice.save!
          boleta = temp_invoice.parse

          render json: {_id: boleta["_id"]}
        else
          puts("Problemas al crear el invoice de un boleta")
        end
      else
        render json: {error: "Problemas con el request."}, status: 400
      end
    end

    def confirm_boleta
      id = params["_id"]
      if Invoice.where(invoiceid: id ).exists?
        @boleta = Invoice.where(invoiceid: id ).first
        @boleta.status = "pagada"
        render partial: 'invoices/ok'
        #moverInsumo(boleta.sku.to_i, boleta.amount) #mover los insumos
        #despacharPedidoB2c(sku, cantidad, direccion, total_plata, id_boleta)
      end


    end

    def fail
      render partial: 'invoices/fail'
    end


    def create
    end


    def accepted
        begin
            @invoice = set_invoice
            @invoice.accepted = true
            render json: {ok: "Factura resuelta recibida exitosamente " }, status: 201
        rescue ActiveRecord::RecordInvalid
            render json:{error: "No se pudo enviar factura resuelta"}, status: 500
        end

        #Change the status of a Invoice in the invoice system.
        #have to validate de id. We generated this Invoice
    end

    def rejected
        begin
            @invoice = set_invoice
            @pinvoice.rejected = true
            render json: {ok: "Factura resuelta recivida exitosamente" }, status: 201
        rescue ActiveRecord::RecordInvalid
            render json:{error: "No se pudo enviar factura resuelta"}, status: 500
        end
        #Change the status of an Invoice in the system.
    end

    def paid
        begin
            @invoice = set_invoice
            @invoice.paid = true
            render json: {ok: "Factura resuelta recibida exitosamente " }, status: 201
        rescue ActiveRecord::RecordNotFound
            render json:{error: "Id no asociado a OC por pagar"}, status: 404
        end
        #change the status of an Invoice inthe system. Check for the transaction.
    end

    def delivered
        begin
            @invoice = set_invoice
            @invoice.delivered = true
            render json: {ok: "Notificacion recibida exitosamente"}, status:201
        rescue ActiveRecord::RecordInvalid
            render json: {error: "No se pudo enviar notificacion"}, status: 500
        end

    end

private

    def invoice_params
        params.require(:invoice).permit(:id,:rejected,:accepted, :paid,:delivered, :account,:date,:proveedor,:cliente,:price, :tax, :total_price ,:po_idtemp,:invoiceid ,:proveedor, :precio, :cantidad)
    end

    def set_invoice
        @invoice = Invoice.find(params[:invoiceid])
    end
end
