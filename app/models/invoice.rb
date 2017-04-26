# == Schema Information
#
# Table name: invoices
#
#  id                :integer          not null, primary key
#  purchase_order_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Invoice < ApplicationRecord
  belongs_to :purchase_order
end
