class Header < ApplicationRecord
  acts_as_draftable

  belongs_to :post, (Rails::VERSION::MAJOR >= 5 ? {optional: true} : {})
end
