# == Schema Information
#
# Table name: purchase_orders
#
#  id             :integer          not null, primary key
#  payment_method :string
#  payment_option :string
#  date           :datetime
#  sku            :string
#  amount         :integer
#  status         :boolean
#  delivery_date  :datetime
#  unit_price     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  poid           :string
#  rejection      :string
#

class PurchaseOrder < ApplicationRecord
  validates :poid, uniqueness: true

end
