class Comment < ApplicationRecord
  acts_as_draftable
  
  belongs_to :post
  belongs_to :user
end
