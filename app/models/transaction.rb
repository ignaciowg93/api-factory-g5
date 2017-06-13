# == Schema Information
#
# Table name: transactions
#
#  id         :integer          not null, primary key
#  _id        :string
#  origin     :string
#  destiny    :string
#  amount     :decimal(, )
#  state      :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Transaction < ApplicationRecord
end
