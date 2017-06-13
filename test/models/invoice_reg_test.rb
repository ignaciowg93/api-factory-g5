# == Schema Information
#
# Table name: invoice_regs
#
#  id         :integer          not null, primary key
#  oc_id      :string
#  status     :integer
#  delivered  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class InvoiceRegTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
