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

require 'test_helper'

class SupplyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
