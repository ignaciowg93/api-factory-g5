class WarehousesController < ApplicationController
  before_action :get_almacenes

    def stocks
      stocks = Warehouse.get_stocks
      render(json: stocks, status: 200)
    end

    # Atender directamente una PO
    def delivery
      Warehouse.to_despacho_and_delivery(params[:id])
    end

end
