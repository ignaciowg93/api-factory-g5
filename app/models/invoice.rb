# == Schema Information
#
# Table name: invoices
#
#  id         :integer          not null, primary key
#  message    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Invoice < ApplicationRecord
  belongs_to :purchase_order
end
