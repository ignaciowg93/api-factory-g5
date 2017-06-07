# == Schema Information
#
# Table name: purchase_orders
#
#  id            :integer          not null, primary key
#  _id           :string
#  client        :string
#  supplier      :string
#  sku           :string
#  delivery_date :datetime
#  amount        :integer
#  delivered_qt  :integer
#  unit_price    :integer
#  channel       :string
#  status        :string
#  notes         :string
#  rejection     :string
#  anullment     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class PurchaseOrder < ApplicationRecord
end
