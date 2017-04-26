# == Schema Information
#
# Table name: purchase_orders
#
#  id             :integer          not null, primary key
#  payment_method :integer
#  payment_option :integer
#  date           :datetime
#  client_id      :integer
#  sku            :string
#  amount         :integer
#  status         :boolean
#  delivery_date  :datetime
#  unit_price     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class PurchaseOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
