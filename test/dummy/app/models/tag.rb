class Tag < ApplicationRecord
  acts_as_draftable

  has_and_belongs_to_many :posts
end
