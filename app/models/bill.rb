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

class Bill < ApplicationRecord
  belongs_to :client
  belongs_to :purchase_order
end
