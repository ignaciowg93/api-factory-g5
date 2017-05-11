# == Schema Information
#
# Table name: products
#
#  id           :integer          not null, primary key
#  sku          :string
#  name         :string
#  price        :decimal(64, 12)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  warehouse_id :integer
#

class Product < ApplicationRecord
  has_many :supplies

    #TODO Referencia a otros productos ( has_many or null).
    #TODO REferencia a clientes y proveedores.( Has_mny o null).
    #JOINT tabla de productos con productos.
    # Usar el trough.
end
