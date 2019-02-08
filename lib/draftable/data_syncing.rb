require_relative "data_synchronizer"

module Draftable
  module DataSyncing
    extend ActiveSupport::Concern

    def with_drafts(&block)

      synchronizers = drafts.map do |draft|
        DataSynchronizer.new(self, draft)
      end

      result = block.call

      if result
        synchronizers.map &:synchronize
      end

      result
    end

  end
end
