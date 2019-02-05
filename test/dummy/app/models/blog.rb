class Blog < ApplicationRecord
  has_and_belongs_to_many :post
end
