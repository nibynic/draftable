module Draftable
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :enable_logging

    def initialize
      @enable_logging = false
    end
  end
end
