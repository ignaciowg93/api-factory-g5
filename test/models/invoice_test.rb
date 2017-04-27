# == Schema Information
#
# Table name: invoices
#
#  id                :integer          not null, primary key
#  purchase_order_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  invoiceid         :string
#  accepted          :boolean
#  rejected          :boolean
#  delivered         :boolean
#  paid              :boolean
#  account           :string
#

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
