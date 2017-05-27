Rails.application.routes.draw do

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  mount Spree::Core::Engine, at: '/'
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
end
