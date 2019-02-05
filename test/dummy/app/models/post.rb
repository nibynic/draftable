class Post < ApplicationRecord
  acts_as_draftable

  has_many :comments
  has_many :photos

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :blogs
end
