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

require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
