class ApplicationRecord < ActiveRecord::Base
  include Draftable::ActsAsDraftable

  self.abstract_class = true
end
