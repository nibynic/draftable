require "draftable/railtie"
require "draftable/configuration"
require "draftable/logger"
require "draftable/acts_as_draftable"

module Draftable
  # Your code goes here...
end

ActiveRecord::Base.class_eval do
  include Draftable::ActsAsDraftable
end
