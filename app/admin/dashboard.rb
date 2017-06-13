require 'http'
require 'digest'
require 'purchase_orders_controller'
require 'product_controller'
include ActiveAdmin::ViewHelper
ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      # span class: "blank_slate" do
      #   span I18n.t("active_admin.dashboard_welcome.welcome")
      #   small I18n.t("active_admin.dashboard_welcome.call_to_action")
      # end
    end



    # STOCK POR PRODUCTO

    @stock = find_qt_by_sku
    columns do
      column do
        panel "Stock" do
          table_for Product.all do
            column("SKU") {|prod| prod.sku}
            column("NAME") {|prod| prod.name}
            column("STOCK") {|prod| @stock[prod.sku]}
          end
        end
      end
    end

    columns do
      column do
        panel "Stock insumos" do
          table_for [[1, 935], [4, 828], [6,228],[8, 1000], [13, 290], [20, 350], [25, 360], [26, 65], [38,20], [41,194], [49,228]]  do
            column("SKU") {|insumo| insumo[0]}
            column("STOCK") {|insumo| @stock[insumo[0].to_s]}
            column("REQUIERED") {|insumo| insumo[1]}
          end
        end
      end
    end


## ORDENES DE COMPRA MANDADAS
panel "Órdenes de compras finalizadas (cantidad):" do
     # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
     # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
     # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
     incompletas = PurchaseOrder.where(status: 'no_completada').count
     completas = PurchaseOrder.where(status: 'finalizada').count
     # monto1 = 0
     # PurchaseOrder.where(status: 'no_completada').each do |po_ord|
     #   monto1 += (po_ord.amount * po_ord.unit_price)
     # end
     # monto2 = 0
     # PurchaseOrder.where(status: 'finalizada').each do |po_ord|
     #   monto2 += (po_ord.amount * po_ord.unit_price)
     # end
     pie_chart({"Exitosas" => completas, "No exitosas" => incompletas})
     #scatter_chart [[incompletas,2], [completas,4]], xtitle: "Cantidad", ytitle: "Monto"
 end
 panel "Órdenes de compras finalizadas (montos):" do
       # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
       # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
       # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
       monto1 = 0
       PurchaseOrder.where(status: 'no_completada').each do |po_ord|
         monto1 += (po_ord.amount * po_ord.unit_price)
       end
       monto2 = 0
       PurchaseOrder.where(status: 'finalizada').each do |po_ord|
         monto2 += (po_ord.amount * po_ord.unit_price)
       end
       column_chart({"Exitosas" => monto2, "No exitosas" => monto1})
       #pie_chart({"Football" => 10, "Basketball" => 5})
       ##
       # line_chart result.each(:as => :hash) { |item|
       #   {name: item.title, data: item.sum_download.count}
       # }
   end

## STOCK POR ALMACEN
    almacenesHash = get_warehouse
    columns do
      column do
        panel "Almacenes" do
          table_for almacenesHash.each do
            column :_id do |almacen|
              almacen["_id"]
            end
            column :usedSpace do |almacen|
              almacen["usedSpace"]
            end
            column :type do |almacen|
              if (almacen["pulmon"])
                "Pulmón"
              elsif (almacen["despacho"])
                "Despacho"
              elsif (almacen["recepcion"])
                "Recepción"
              else
                "Intermedio"
              end
            end
          end
        end
      end
    end

    columns do
          column do
            panel "Órdenes de producción" do
              table_for ProductionOrder.all.order('created_at desc') do
                column("ID") {|prod| prod.id }
                column("SKU") {|prod| prod.sku}
                column("AMOUNT") {|prod| prod.amount}
                column("Produced for") {|prod| prod.oc_id}
                column("Est. DATE") {|prod| prod.est_date}
              end
            end
          end
        end

    ##BOLETAS GENERADAS ## Esto deberían ser invoices. No Purchase Order. Cambiar junto con los métodos de creación de boletas.
    panel "Boletas Generadas(monto)" do
       # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
       # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
       # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
       monto1 = Invoice.where(status: 'pendiente').count
       monto2 = Invoice.where(status: 'pagada').count
       monto4 = Invoice.where(status: 'rechazada').count
       monto3 = Invoice.where(status: 'anulada').count



       column_chart({"Pendientes" => monto1, "Pagadas" => monto2, "Rechazadas" => monto4, "Anuladas" => monto3})
       #pie_chart({"Football" => 10, "Basketball" => 5})
       ##
       # line_chart result.each(:as => :hash) { |item|
       #   {name: item.title, data: item.sum_download.count}
       # }
   end

   panel "Boletas Generadas(monto)" do
      # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
      # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
      # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
      monto1 = 0
      Invoice.where(status: 'pendiente').each do |boleta|
        monto1 += (boleta.total_price)
      end
      monto2 = 0
      Invoice.where(status: 'pagada').each do |boleta|
        monto2 += (boleta.total_price)
      end
      monto3 = 0
      Invoice.where(status: 'anulada').each do |boleta|
        monto3 += (boleta.total_price)
      end
      monto4 = 0
      Invoice.where(status: 'rechazada').each do |boleta|
        monto4 += (boleta.total_price)
      end
      column_chart({"Pendientes" => monto1, "Pagadas" => monto2, "Rechazadas" => monto4, "Anuladas" => monto3})
      #pie_chart({"Football" => 10, "Basketball" => 5})
      ##
      # line_chart result.each(:as => :hash) { |item|
      #   {name: item.title, data: item.sum_download.count}
      # }
  end



     columns do
      column do
        panel "Boletas generadas" do
          table_for Invoice.where(boleta: true).order('created_at desc') do
            column("ID") {|prod| prod.id }
            column("CLIENT") {|prod| prod.cliente}
            column("TOTAL PRICE") {|prod| prod.total_price}
          end
        end
      end
    end

    ##TRANSACCIONES EXITOSAS


    panel "Transacciones Generadas(cantidad)" do
       # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
       # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
       # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
       monto1 = Transaction.where(state: true).count
       monto2 = Transaction.where(state: false).count




       pie_chart({"Aprobadas" => monto1, "Rechazadas" => monto2})
       #pie_chart({"Football" => 10, "Basketball" => 5})
       ##
       # line_chart result.each(:as => :hash) { |item|
       #   {name: item.title, data: item.sum_download.count}
       # }
   end

    columns do
      column do
        panel "Transacciones Aprobadas" do
          table_for Transaction.where(:state ==true).order('created_at desc') do
            column("ID") {|tran| tran._id }
            column("ORIGEN") {|tran| tran.origin }
            column("DESTINO") {|tran| tran.destiny }
            column("MONTO") {|tran| tran.amount }

          end
        end
      end
    end


    columns do
      column do
        panel "Transacciones Rechazadas" do
          table_for Transaction.where(:state ==false).order('created_at desc') do
            column("ID") {|tran| tran._id }
            column("ORIGEN") {|tran| tran.origin }
            column("DESTINO") {|tran| tran.destiny }
            column("MONTO") {|tran| tran.amount }

          end
        end
      end
    end
    #

   # content


  columns do
        column do
          panel "Órdenes de Compra FTP Recibidas" do
            table_for PurchaseOrder.where(status: "creada", channel: "ftp").order('created_at desc') do
              column("ID") {|poid| poid._id }
              column("SKU") {|poid| poid.sku}
              column("AMOUNT") {|poid| poid.amount}
              column("DELIVERED AMOUNT") {|poid| poid.delivered_qt}
            end
          end
        end
      end

      columns do
            column do
              panel "Órdenes de Compra FTP Rechazadas" do
                table_for PurchaseOrder.where(status: "rechazada", channel: "ftp").order('created_at desc') do
                  column("ID") {|poid| poid._id }
                  column("SKU") {|poid| poid.sku}
                  column("AMOUNT") {|poid| poid.amount}
                  column("DELIVERED AMOUNT") {|poid| poid.delivered_qt}
                  column("MOTIVO RECHAZO") {|poid| poid.rejection}

                end
              end
            end
          end


      columns do
            column do
              panel "Órdenes de Compra FTP Completadas" do
                table_for PurchaseOrder.where(status: "finalizada", channel: "ftp").order('created_at desc') do
                  column("ID") {|poid| poid._id }
                  column("SKU") {|poid| poid.sku}
                  column("AMOUNT") {|poid| poid.amount}
                  column("DELIVERED AMOUNT") {|poid| poid.delivered_qt}
                end
              end
            end
          end




      panel "Órdenes de compras FTP " do
           # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
           # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
           # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
           creadas = PurchaseOrder.where(status: 'creada').count
           completas = PurchaseOrder.where(status: 'finalizada').count
           rechazadas = PurchaseOrder.where(status: 'rechazada').count
          # monto1 = 0
           # PurchaseOrder.where(status: 'no_completada').each do |po_ord|
           #   monto1 += (po_ord.amount * po_ord.unit_price)
           # end
           # monto2 = 0
           # PurchaseOrder.where(status: 'finalizada').each do |po_ord|
           #   monto2 += (po_ord.amount * po_ord.unit_price)
           # end
           pie_chart({"Recibidas" => creadas, "Completas" => completas , "Rechazadas" => rechazadas})
           #scatter_chart [[incompletas,2], [completas,4]], xtitle: "Cantidad", ytitle: "Monto"
       end






end

end
