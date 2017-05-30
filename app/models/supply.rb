class Supply < ApplicationRecord
  belongs_to :product
  has_many :sellers
end
