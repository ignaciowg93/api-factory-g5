require 'net/ftp'
require 'net/ssh'
require 'net/sftp'

class Ftp < ApplicationRecord



  def self.prueba
    puts 'Esto es un test'
  end

    @@tiempo_inicio = Time.new(2017, 6, 7, 5, 0, 0, "+00:00") # cambiar fecha


    def self.tiempo_inicio
        @@tiempo_inicio
    end
    def self.ultimo_tiempo()
        @@tiempo_inicio
    end

    def self.prueba()
      host = 'integra17dev.ing.puc.cl'
      port = '22'
      user = 'grupo5'
      password = 'jR4mgD9tb6BNk2WM'
      Net::SFTP.start(host,user, :password=>password) do |sftp|
            sftp.dir.foreach("/pedidos") do |entry|
                  if entry.file?()
                    sftp.download!("/pedidos/"+entry.name, "/Users/TR/Desktop/test/"+entry.name)
                    end
            end
      end
    end


    def self.ordenes_compra()
      puts "Parto el ftp"
      host = 'integra17dev.ing.puc.cl'
      port = '22'
      user = 'grupo5'
      password = 'jR4mgD9tb6BNk2WM'

      tiempo_mayor_local = tiempo_inicio

      Net::SFTP.start(host,user, :password=>password) do |sftp|
            sftp.dir.foreach("/pedidos") do |entry|
                if entry.file?()
                    nombre_split = entry.longname.split
                    nombre = nombre_split[8]
                    mes = nombre_split[5]
                    dia = nombre_split[6]
                    horas = nombre_split[7].split(":")
                    hora = horas[0]
                    minuto = horas[1]

                    tiempo = Time.new('2017', mes, dia, hora, minuto, '0', "+00:00")
                    #Time.new(2002, 10, 31, 2, 2, 2, "+00:00")
                    if tiempo > tiempo_inicio
                        if tiempo > tiempo_mayor_local
                            tiempo_mayor_local = tiempo
                        end

                        data = sftp.download!("/pedidos/"+entry.name)
                        doc = Nokogiri::XML(data)
                        thing = doc.at_xpath('order')
                        orden_id = thing.at_xpath('//id').content
                        orden_sku = thing.at_xpath('//sku').content
                        orden_qty = thing.at_xpath('//qty').content

                        #Consulta el stock por SKU
                        respuesta = Warehouse.consultar(orden_sku)
                        seguir = false

                        existe_oc = PurchaseOrder.check_purchase_order(orden_id)
                        #Retorna true si existe, false si no

                        if respuesta['stock'].to_i > orden_qty.to_i && existe_oc

                            orden_de_compra = PurchaseOrder.where(:_id => orden_id)

                            #Revisa nuestros SKU y ve si el precio de compra es mayor o menor.

                            if orden_sku == "3"
                                    if orden_de_compra['precioUnitario'].to_i> 117 #precio sku 3
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "5"
                                    if orden_de_compra['precioUnitario'].to_i> 428 #precio sku 5
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end
                            end
                            if orden_sku == "7"
                                    if orden_de_compra['precioUnitario'].to_i> 290 #precio sku 7
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "9"
                                    if orden_de_compra['precioUnitario'].to_i> 350 #precio sku 9
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end
                            end
                            if orden_sku == "11"
                                    if orden_de_compra['precioUnitario'].to_i> 247 #precio sku 11
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "15"
                                    if orden_de_compra['precioUnitario'].to_i> 276 #precio sku 15
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "17"
                                    if orden_de_compra['precioUnitario'].to_i> 821 #precio sku 17
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "22"
                                    if orden_de_compra['precioUnitario'].to_i> 336 #precio sku 22
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "25"
                                    if orden_de_compra['precioUnitario'].to_i> 93 #precio sku 25
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "52"
                                    if orden_de_compra['precioUnitario'].to_i> 410 #precio sku 52
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end
                            if orden_sku == "56"
                                    if orden_de_compra['precioUnitario'].to_i> 479 #precio sku 56
                                        seguir = true
                                        orden_precio = orden_de_compra['precioUnitario']
                                    end

                            end


                            if seguir

                                    #Va al sistema de facturas y la acepta
                                    PurchaseOrder.receivePurchaseOrder(orden_id)

                                    #Mueve el producto a la de despacho
                                    Warehouse.move_product(orden_sku, orden_qty)

                                    #Emite la boleta/factura
                                    Invoice.create_invoice(orden_id.to_s)

                                    #Despacha el pedido de la bodega
                                    Warehouse.dispatch_order(orden_id, orden_sku, orden_qty, orden_precio.to_s)


                            else
                                    PurchaseOrder.rejectPurchaseOrder(orden_id, "Esta por debajo del Precio")
                                    #puts "rechazar Oc por precio"
                            end

                        else
                            PurchaseOrder.rejectPurchaseOrder(orden_id, "No tenemos stock")
                            #puts "rechazar Oc por stock" + orden_sku.to_s + " el stock" + orden_qty.to_s+ " con odId = "+ orden_id
                        end
                    end
                    #break
                end

        end
        if tiempo_mayor_local > tiempo_inicio
            tiempo_inicio = tiempo_mayor_local
        end

      puts "Termine el ftp"
    end
end

end
