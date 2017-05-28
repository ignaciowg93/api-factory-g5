Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

#Productos
  get 'products/', to: 'product#index'


#Ordenes de Compra
  #put 'purchase_orders/:id', to: 'purchase_orders#receive'
  put 'purchase_orders/:id', to: 'application#receive'

  patch 'purchase_orders(/:id(/accepted))', to: 'purchase_orders#accepted'

  patch 'purchase_orders(/:id(/rejected))' , to: 'purchase_orders#rejected'

#Facturas

  put 'invoices/:id' , to: 'invoices#receive'

  patch 'invoices(/:id(/accepted))' , to: 'invoice#accepted'

  patch 'invoices(/:id(/rejected))' , to: 'invoice#rejected'

  patch 'invoices(/:id(/delivered))' , to: 'invoice#delivered'

  patch 'invoices(/:id(/paid))' , to: 'invoice#paid'

####Lista de Precios

  get 'api/publico/precios', to: 'product#prices'

  get 'prueba', to: 'application#prueba'
end
