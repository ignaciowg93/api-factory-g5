
include ActiveAdmin::ViewHelper
ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        span I18n.t("active_admin.dashboard_welcome.welcome")
        small I18n.t("active_admin.dashboard_welcome.call_to_action")
      end
    end



    # STOCK POR PRODUCTO

    columns do
      column do
        panel "Products" do
          ul do
            Product.all.map do |p|
              li p.name + " : " + get_stock_by_sku(p.sku).to_s
            end
          end
        end
      end
    end

## ORDENES DE COMPRA MANDADAS
    columns do
      column do
        panel "Órdenes de producción" do
          table_for ProductionOrder.all.order('created_at desc') do
            column("ID") {|prod| prod.id }
            column("SKU") {|prod| prod.sku}
            column("AMOUNT") {|prod| prod.amount}
          end
        end
      end
    end

## STOCK POR ALMACEN

    columns do
      column do
        panel "Almacenes" do
          almacenesHash = get_warehouse
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

    ##BOLETAS GENERADAS ## Esto deberían ser invoices. No Purchase Order. Cambiar junto con los métodos de creación de boletas.
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
    # columns do
    #   column do
    #     panel "Ordenes de Compra Aprobadas" do
    #       table_for PurchaseOrder.where(:status =='accepted').order('created_at desc') do
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
    #       table_for PurchaseOrder.where(:status =='rejected').order('created_at desc') do
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
