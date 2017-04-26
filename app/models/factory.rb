# == Schema Information
#
# Table name: factories
#
#  id         :integer          not null, primary key
#  status     :integer
#  busy       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Factory < ApplicationRecord
end
