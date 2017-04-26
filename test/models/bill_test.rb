# == Schema Information
#
# Table name: bills
#
#  id          :integer          not null, primary key
#  supplier    :string
#  client      :string
#  value       :integer
#  tax         :integer
#  total_value :integer
#  pay_status  :integer
#  pay_date    :datetime
#  reject      :string
#  cancel      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class BillTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
