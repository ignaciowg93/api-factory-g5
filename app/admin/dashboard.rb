require 'http'
require 'digest'
require 'purchase_orders_controller'
base_route = "https://integracion-2017-prod.herokuapp.com/oc/"
#include ActiveAdmin::ViewHelper
ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      # span class: "blank_slate" do
      #   span I18n.t("active_admin.dashboard_welcome.welcome")
      #   small I18n.t("active_admin.dashboard_welcome.call_to_action")
      # end
    end



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

    panel "Boletas generadas (cantidad):" do
        # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
        # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
        # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
        incompletas = PurchaseOrder.where(status: 'no_completada').count
        completas = PurchaseOrder.where(status: 'finalizada').count
        column_chart({"Exitosas" => completas, "No exitosas" => incompletas})
        #pie_chart({"Football" => 10, "Basketball" => 5})
        ##
        # line_chart result.each(:as => :hash) { |item|
        #   {name: item.title, data: item.sum_download.count}
        # }
    end

    panel "Boletas generadas (monto):" do
        # line_chart   Content.pluck("download").uniq.map { |c| { title: c, data: Content.where(download: c).group_by_day(:updated_at, format: "%B %d, %Y").count }  }, discrete: true
        # column_chart Content.group_by_hour_of_day(:updated_at, format: "%l %P").order(:download).count, {library: {title:'Downloads for all providers'}}
        # column_chart Content.group(:title).order('download DESC').limit(5).sum(:download)
        incompletas = PurchaseOrder.where(status: 'no_completada').count
        completas = PurchaseOrder.where(status: 'finalizada').count
        column_chart({"Exitosas" => completas, "No exitosas" => incompletas})
        #pie_chart({"Football" => 10, "Basketball" => 5})
        ##
        # line_chart result.each(:as => :hash) { |item|
        #   {name: item.title, data: item.sum_download.count}
        # }
    end

    ##BOLETAS GENERADAS ## Esto deberían ser invoices. No Purchase Order. Cambiar junto con los métodos de creación de boletas.
     columns do
      column do
        panel "Boletas generadas (ahora lee PO en vd)" do
          table_for PurchaseOrder.all.order('created_at desc') do
            column("ID") {|prod| prod.id }
            column("CLIENT") {|prod| prod.client}
            column("SKU") {|prod| prod.sku}
            column("AMOUNT") {|prod| prod.amount}
            column("UNIT PRICE") {|prod| prod.unit_price}
            column("DELIVERY DATE"){|prod| prod.delivery_date}
          end
        end
      end
    end

    ## ORDENES DE COMPRA RECIBIDAS
    columns do
      column do
        panel "Órdenes de compra recibidas" do
          table_for PurchaseOrder.all.order('created_at desc') do
            column("ID") {|prod| prod.id }
            column("SKU") {|prod| prod.sku}
            column("AMOUNT") {|prod| prod.amount}
            column("STATUS") {|prod| prod.status}
            column("CLIENT") {|prod| prod.client}
          end
        end
      end
    end

    ## STOCK POR PRODUCTO

    # columns do
    #   column do
    #     panel "Products" do
    #       ul do
    #         Product.all.map do |p|
    #           li p.name + " : " + get_stock_by_sku(p.sku).to_s
    #         end
    #       end
    #     end
    #   end
    # end

    #incompletas = PurchaseOrder.where(status: 'no_completada').count
    #completas = PurchaseOrder.where(status: 'finalizada').count
    #puts "cuenta: #{incompletas}/#{completas}"


## ORDENES DE PRODUCCIÓN MANDADAS
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

## STOCK POR ALMACEN

    # columns do
    #   column do
    #     panel "Almacenes" do
    #       almacenesHash = get_warehouse
    #       table_for almacenesHash.each do
    #         column :_id do |almacen|
    #           almacen["_id"]
    #         end
    #         column :usedSpace do |almacen|
    #           almacen["usedSpace"]
    #         end
    #         column :type do |almacen|
    #           if (almacen["pulmon"])
    #             "Pulmón"
    #           elsif (almacen["despacho"])
    #             "Despacho"
    #           elsif (almacen["recepcion"])
    #             "Recepción"
    #           else
    #             "Intermedio"
    #           end
    #         end
    #       end
    #     end
    #   end
    # end

    #
    # ##TRANSACCIONES EXITOSAS
    # columns do
    #   column do
    #     panel "Ordenes de Compra Aprobadas" do
    #       table_for PurchaseOrder.where(status: 'aceptada').order('created_at desc') do
    #         column("ID") {|prod| prod.id }
    #         column("CLIENT") {|prod| prod.client}
    #         column("SKU") {|prod| prod.sku}
    #         column("AMOUNT") {|prod| prod.amount}
    #         column("UNIT PRICE") {|prod| prod.unit_price}
    #         column("DELIVERY DATE"){|prod| prod.delivery_date}
    #       end
    #     end
    #   end
    # end
    #
    # ##TRANSACCIONES RECHAZADAS
    # columns do
    #   column do
    #     panel "Ordenes de Compra Rechazadas" do
    #       table_for PurchaseOrder.where(status: 'rechazada').order('created_at desc') do
    #         column("ID") {|prod| prod.id }
    #         column("CLIENT") {|prod| prod.client}
    #         column("SKU") {|prod| prod.sku}
    #         column("AMOUNT") {|prod| prod.amount}
    #         column("UNIT PRICE") {|prod| prod.unit_price}
    #         column("DELIVERY DATE"){|prod| prod.delivery_date}
    #       end
    #     end
    #   end
    # end



    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
end
