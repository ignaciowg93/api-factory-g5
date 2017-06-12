Rails.application.routes.draw do
  scope 'api' do
    ActiveAdmin.routes(self)
    get '/', to: 'admin/dashboard#index'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

#Productos
  get 'products/', to: 'product#index'

#
  # Agregar el Metodo find para buscar un producto con el id como parametro
  # get 'products/:sku', to: 'product#find'
  get 'products/:sku' => 'product#find'

  get 'tienda/ok/:_id' => 'invoices#confirm_boleta'

  get 'tienda/fail' => 'invoices#fail'
#

#Ordenes de Compra
  #put 'purchase_orders/:id', to: 'purchase_orders#receive'
  #put 'purchase_orders/:id', to: 'application#receive'

  patch 'purchase_orders(/:id(/accepted))', to: 'purchase_orders#accepted'

  patch 'purchase_orders(/:id(/rejected))' , to: 'purchase_orders#rejected'

#Facturas

  put 'invoices/:id' , to: 'invoices#receive'

  patch 'invoices(/:id(/accepted))' , to: 'invoices#accepted'

  patch 'invoices(/:id(/rejected))' , to: 'invoices#rejected'

  patch 'invoices(/:id(/delivered))' , to: 'invoices#delivered'

  patch 'invoices(/:id(/paid))' , to: 'invoices#paid'

  put 'api/boleta' , to: 'invoices#generate_boleta'

####Lista de Precios

  get 'api/publico/precios', to: 'product#prices'

  get 'products', to: 'product#index'

## Metodos manuales para dashboard
  post 'produce', to: 'interaction#produce'
  put 'purchase_orders/:id', to: 'purchase_orders#receive_b2b'
  post 'purchase_orders/ftp', to: 'purchase_orders#receive_ftp'
  put 'despachar/:id', to: 'interaction#despachar'

  # temporary
  get 'stock', to: 'interaction#get_stocks'
end
