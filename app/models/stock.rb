# == Schema Information
#
# Table name: stocks
#
#  id           :integer          not null, primary key
#  sku          :string
#  totalAmount  :integer
#  selledAmount :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Stock < ApplicationRecord
end
