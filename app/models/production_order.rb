# == Schema Information
#
# Table name: production_orders
#
#  id         :integer          not null, primary key
#  sku        :string
#  amount     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  oc_id      :string
#  est_date   :string
#

class ProductionOrder < ApplicationRecord
end
