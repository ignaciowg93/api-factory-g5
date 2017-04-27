Rails.application.routes.draw do
	root 'application#hello'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

#Productos
  get 'products/', to: 'product#index'


#Ordenes de Compra
  put 'purchase_orders/:id', to: 'purchase_orders#receive'

  
  patch 'purchase_orders(/:id(/accepted))', to: 'purchase_orders#accepted'

  patch 'purchase_orders(/:id(/rejected))' , to: 'purchase_orders#rejected'

#Facturas

  put 'invoices/:id' , to: 'invoice#receive'

  patch 'invoices/:id/accepted' , to: 'invoice#recieve'
  
  patch 'invoices/:id/rejected' , to: 'invoice#recieve'
  
  patch 'invoices/:id/delivered' , to: 'invoice#recieve'

  patch 'invoices/:id/paid' , to: 'invoice#recieve'


end
