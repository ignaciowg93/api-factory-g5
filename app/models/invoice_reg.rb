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

class InvoiceReg < ApplicationRecord
end
