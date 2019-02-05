class Tag < ApplicationRecord
  acts_as_draftable

  has_and_belongs_to_many :posts, inverse_of: :tags
end
