Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

#Productos
  get 'products/', to: 'products#index'


#Ordenes de Compra
  put 'purchase_orders/:id', to: 'purchase_orders#receive'

  patch 'purchase_order/:id/accepted' , to: 'purchase_orders#accepted'

  patch 'purchase_order/:id/rejected' , to: 'purchase_orders#rejected'
end
