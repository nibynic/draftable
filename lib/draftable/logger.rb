module Draftable
  def self.logger
    @logger ||= Logger.new
  end

  class Logger
    def debug(message, *args)
      if Draftable.configuration.enable_logging
        Rails.logger.debug(format_message(message, *args))
      end
    end

    private

    def format_message(message, *args)
      "[Draftable] #{message}".gsub("?") { format_argument(args.shift) }
    end

    def format_argument(arg)
      if arg.is_a? ActiveRecord::Base
        [arg.class.name, arg.id || "new"].join("#")
      else
        arg
      end
    end
  end
end
