class BoletasController < ApplicationController
  def ok
    id_boleta = params[:_id]
    #Llamar a la boleta de b2c
    #@boleta = B2c.find_by _id: id_boleta
    
    #MANDAR A DESPACHAR
    direccion = @boleta.direccion
    sku = @boleta.sku
    cantidad = @boleta.cantidad
    id_boleta = @boleta._id
    total_plata = @boleta.total
    iva = @boleta.iva
    bruto = @boleta.bruto
    proveedor = @boleta.proveedor
    cliente = @boleta.cliente
    
    ##Despachar Mover a despacho
    moverInsumo(sku.to_i, cantidad) #mover los insumos
    despacharPedidoB2c(sku, cantidad, direccion, total_plata, id_boleta)
    @boleta.estado = "confirmada"
    @boleta.save
    
  end

  def fail
  end
end
