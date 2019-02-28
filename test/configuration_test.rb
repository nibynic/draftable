require 'test_helper'

module Draftable
  class ConfigurationTest < ActiveSupport::TestCase
    test "it provides default values" do
      assert_equal false, Draftable.configuration.enable_logging
    end

    test "it stores user-defined values" do
      Draftable.configure do |config|
        config.enable_logging = true
      end
      
      assert_equal true, Draftable.configuration.enable_logging
    end
  end
end
