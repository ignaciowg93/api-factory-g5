# == Schema Information
#
# Table name: accounts
#
#  id          :integer          not null, primary key
#  invoice_id  :string
#  _id         :string
#  tipo        :string
#  paid        :boolean
#  date_to_pay :datetime
#  cuota       :boolean
#  amount      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Account < ApplicationRecord
end
