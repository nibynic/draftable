class Footer < ApplicationRecord
  belongs_to :post, (Rails::VERSION::MAJOR >= 5 ? {optional: true} : {})
end
