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
      # revisar la factura
      # aceptarla -> avisar al emisor de la factura -> pagarla -> avisar
      # rechazarla -> avisar al emisor de la factura
      bank_account_presence = params.key?(:bank_account) &&
                                !params[:bank_account].nil? &&
                                !params[:bank_account].empty?

      unless bank_account_presence
        render(json: { error: 'Identificador de la cuenta de pago inválido' }, status: 400) &&
          return
      end
      resp = Invoice.rec_invoice(params[:id])
      puts("resp es #{resp}")
      if !resp
        render json:{error: "Factura no encontrada"} , status:400
      else
        render json:{ok: "Factura recibida exitosamente"} , status:200
        puts("Resp code es #{resp}")
        to_put = ""
        Thread.new do
          to_put = Invoice.atender_factura(resp, params[:id], params[:bank_account])
          puts "dentro del thread: #{to_put}"
        end
      end

        #
        # # We receive the invoice ID from the provider.  Recibimos la cuenta a la cual tenemos que transferir.
        # begin
        #     @invoice = Invoice.new(invoice_params)
        #     @invoice.invoiceid = params[:id]
        #     if @invoice.save
        #         @invoice.save!
        #         render json: {ok: "notificación recibida exitosamente"} , status: 201
        #     else
        #         render json: {error: "No se pudo enviar resolución"}, status: 500
        #     end
        #  rescue ActiveRecord::RecordNotFound
        #     render json:{error: "Id no asociado a Factura por resolver"}, status: 404
        #  #rescue ActionController::ParameterMissing
        #   #   render json:{error:"Falta algún parámetro"}, status: 422
        #  end
    end

    def accepted
        begin
            factura = Invoice.find_by(invoiceid: params[:id])
            puts "Accepted - Me avisan desde factura #{factura.invoiceid}"
            sku = factura.sku
            qty = factura.amount
            orden_Id = factura.po_idtemp
            oc = PurchaseOrder.find_by(_id: orden_Id)
            almacen_recepcion = oc.direccion
            precio = oc.unit_price
            canal = "b2b"
            client_url = Client.find_by(name: factura.cliente).url

            if Invoice.check_accepted(params[:id])
              # en el sistema no existe un estado aceptado, así es que no lo puedo marcar
              factura.accepted = true
              #Change the status of a Invoice in the invoice system.
              factura.save!
              render json: {ok: "Factura resuelta recibida exitosamente " }, status: 201
              # se despacha (omitir el thread completo si se decide)
              Thread.new do
                Warehouse.to_despacho_and_delivery(ordenId)
                # notificar del despacho
                despachado = HTTP.headers(:accept => "application/json", "X-ACCESS-TOKEN" => "#{Rails.configuration.my_id}").patch("#{client_url}invoices/#{params[:id]}/delivered")
              end
            else
              render json:{error: "Factura rechazada o anulada"}, status: 403
            end
        rescue ActiveRecord::RecordInvalid
          #have to validate de id. We generated this Invoice -> nunca pasa pq tira que la ruta no existe entonces
            render json:{error: "No se pudo recibir resolucion factura - no se encuentra"}, status: 500
        end
    end

    def rejected
        begin
            factura = Invoice.find_by(invoiceid: params[:id])
            puts "Rejected - Me avisan desde factura #{factura.invoiceid}"
            #Change the status of an Invoice in the system.
            factura.rejected = true
            factura.save!
            render json: {ok: "Factura resuelta recibida exitosamente" }, status: 201
        rescue ActiveRecord::RecordInvalid
            render json:{error: "No se pudo recibir resolucion factura"}, status: 500
        end
    end

    def paid
      id_transaction_presence = params.key?(:id_transaction) &&
                                !params[:id_transaction].nil? &&
                                !params[:id_transaction].empty?

      unless id_transaction_presence
        render(json: { error: 'Debe entregar el id de una transacción' }, status: 400) &&
          return
      end
      begin
        transaction_rec = HTTP.headers(:accept => "application/json").get(Rails.configuration.base_route_banco + "trx/" + params[:id_transaction], :json => {:id_transaction => params[:id_transaction]})
        puts "transaction es #{transaction_rec}"
        if transaction_rec.code == 200
          recibido = transaction_rec.parse[0]["monto"]
          puts "recibido es #{recibido}"
          factura = Invoice.find_by(invoiceid: params[:id])
          por_pagar = factura.total_price
          puts "por pagar es #{por_pagar}"
          if recibido >= por_pagar
            # revisar que esté como pendiente en el sistema
            if Invoice.por_pagar(params[:id])
              # marca en el sistema como pagado
              marca_pagado = HTTP.headers(:accept => "application/json").post(Rails.configuration.base_route_factura + "pay", :json => {:id => params[:id]})
              puts "marca_pagado: #{marca_pagado}"
              # marca factura como pagado
              factura.paid = true
              factura.save!
              #responde
              render json: {ok: "Aviso de pago recibido exitosamente, confirmado." }, status: 201
            else
              render json:{error: "Id no asociado a factura por pagar"}, status: 404
            end
          else
            render json: {ok: "Transacción no cumple el monto" }, status: 404
          end
        else
          render json: {ok: "Transacción no existente" }, status: 404
        end
      rescue ActiveRecord::RecordNotFound
          render json:{error: "Id no asociado a factura por pagar"}, status: 404
      end
      #change the status of an Invoice inthe system. Check for the transaction.
    end

    def delivered
        begin
            # marcar invoice delivered en BDD delivered
            factura = Invoice.find_by(invoiceid: params[:id])
            puts "Delivered - Me avisan desde factura #{factura.invoiceid}"
            #Change the status of an Invoice in the system.
            factura.delivered = true
            factura.save!
            # marcar OC completa en BDD
            orden_Id = factura.po_idtemp
            oc = PurchaseOrder.find_by(_id: orden_Id)
            oc.update(status: "finalizada")
            render json: {ok: "Notificacion recibida exitosamente"}, status:201
        rescue ActiveRecord::RecordInvalid
            render json: {error: "No se pudo enviar notificacion"}, status: 500
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
      Rails.logger.debug (temp_invoice)
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
          puts "BBBBBBBBBBBBBBBBBBBBBB"
          puts boleta
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
      if Invoice.where(invoiceid: id ).exist?
        boleta = Invoice.where(invoiceid: id ).first
        boleta.update(status: "pagada")
        # poid = boleta.po_idtemp
        # Warehouse.to_despacho_and_delivery(poid)
      end
    end

    def fail
      id = params["_id"]
      boleta = Invoice.find_by(invoiceid: id )
      if !boleta.nil?
        boleta.status = "cancelada"
        # poid = boleta.po_idtemp
        # PurchaseOrder.find_by(_id: poid).update(anullment: "cancelada")
      end
    end


    def create
    end






private

    def invoice_params
        params.require(:invoice).permit(:id,:rejected,:accepted, :paid,:delivered, :bank_account,:date,:proveedor,:cliente,:price, :tax, :total_price ,:po_idtemp,:invoiceid ,:proveedor, :precio, :cantidad, :id_transaction)
    end

    def set_invoice
        @invoice = Invoice.find(params[:invoiceid])
    end
end
