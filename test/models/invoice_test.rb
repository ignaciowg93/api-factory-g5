# == Schema Information
#
# Table name: invoices
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  invoiceid   :string
#  accepted    :boolean
#  rejected    :boolean
#  delivered   :boolean
#  paid        :boolean
#  account     :string
#  price       :integer
#  tax         :integer
#  total_price :integer
#  proveedor   :string
#  cliente     :string
#  date        :datetime
#  po_idtemp   :string
#  boleta      :boolean
#  status      :string
#  amount      :integer
#  sku         :string
#

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
