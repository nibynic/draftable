class Post < ApplicationRecord
  acts_as_draftable

  has_one :header
  has_one :footer

  has_many :comments
  has_many :photos

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :blogs
end
