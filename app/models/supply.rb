# == Schema Information
#
# Table name: supplies
#
#  id              :integer          not null, primary key
#  sku             :string
#  requierment     :integer
#  seller          :string
#  time            :decimal(, )
#  product_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  stock_reservado :integer
#

class Supply < ApplicationRecord
  belongs_to :product
  has_many :sellers
end
