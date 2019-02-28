require 'test_helper'
require "spy"

module Draftable
  class LoggerTest < ActiveSupport::TestCase
    test "it logs messages only if loggin is enabled" do
      debug_spy = Spy.on(Rails.logger, :debug)
      format_spy = Spy.on_instance_method(Draftable::Logger, :format_message).and_return("formatted message")

      Draftable.configuration.enable_logging = false
      Draftable.logger.debug("debug message")

      assert_equal 0, debug_spy.calls.length

      Draftable.configuration.enable_logging = true
      Draftable.logger.debug("debug message", :some_value)

      assert_equal ["formatted message"], debug_spy.calls.first.args
      assert_equal ["debug message", :some_value], format_spy.calls.first.args

      debug_spy.unhook
      format_spy.unhook
      Draftable.configuration.enable_logging = false
    end

    test "it serializes record to a human readable format" do
      post = create(:post)

      message = Draftable::Logger.new.send(:format_message, "new: ?, existing: ?", build(:post), post)

      assert_equal "[Draftable] new: Post#new, existing: Post##{post.id}", message
    end
  end
end
