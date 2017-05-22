require 'http'
require 'digest'
require 'purchase_orders_controller'
base_route = "https://integracion-2017-dev.herokuapp.com/oc/"
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