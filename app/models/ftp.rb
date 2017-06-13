require 'net/ftp'
require 'net/ssh'
require 'net/sftp'
class Ftp < ApplicationRecord



    @@tiempo_inicio = Time.new(2017, 6, 7, 5, 0, 0, "+00:00")


  def self.prueba
    puts 'Esto es un test'
  end

    def self.tiempo_inicio
        @@tiempo_inicio
    end


    def self.ultimo_tiempo()
        @@tiempo_inicio
    end



    def self.check_to_log()
      host = 'integra17dev.ing.puc.cl'
      port = '22'
      user = 'grupo5'
      password = 'jR4mgD9tb6BNk2WM'
      Net::SFTP.start(host,user, :password=>password) do |sftp|
        sftp.dir.foreach("/pedidos") do |entry|
          if entry.file?()
            data = sftp.download!("/pedidos/"+entry.name)

            doc = Nokogiri::XML(data)
            thing = doc.at_xpath('order')
            orden_id = thing.at_xpath('//id').content
            orden_sku = thing.at_xpath('//sku').content
            orden_qty = thing.at_xpath('//qty').content

            response = PurchaseOrder.getPurchaseOrder(orden_id)
            if response.code == 200
              product = Product.find_by(sku: orden_sku)
              stock_propio = Warehouse.get_stock_by_sku(product)
              if orden_qty.to_i >= stock_propio
                puts("La cantidad solicitada es mayor a la nuestra. Pedido: #{orden_qty}  Nuestro #{stock_propio} del producto #{orden_sku}" )
              else
                puts("La cantidad solicitada es menor a la nuestra. Pedido: #{orden_qty}  Nuestro #{stock_propio} del producto #{orden_sku}" )
              end
            else
              puts("No se pudo recuperar la ORden en el Sistema")
            end
          end
        end
      end
    end

    def self.ordenes_compra()
        # Automatically serve all requests, in order
        Net::SFTP.start(Rails.configuration.host, Rails.configuration.ftp_user,
                      password: Rails.configuration.ftp_pass) do |sftp|
        sftp.dir.foreach('/pedidos') do |entry|
          next unless entry.file?
          nombre_split = entry.longname.split
          nombre = nombre_split[8]

          data = sftp.download!('/pedidos/' + entry.name)
          doc = Nokogiri::XML(data)
          thing = doc.at_xpath('order')
          poid = thing.at_xpath('//id').content

          # Load PO, or create
          order = PurchaseOrder.find_by(_id: poid) ||
                  PurchaseOrder.check_purchase_order(poid, 'distribuidor') &&
                  PurchaseOrder.find_by(_id: poid)

          next unless order && order.can_be_served?
          Invoice.create_invoice(poid, false)
          Warehouse.to_despacho_and_delivery(poid)

        end
      end
    end

  


end
