require_relative "data_syncing"
require_relative "draft_building"
require_relative "options_normalization"

module Draftable
  module ActsAsDraftable
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_draftable(options = {})
        include Draftable::DataSyncing
        include Draftable::DraftBuilding
        include Draftable::OptionsNormalization

        @draftable_options = options
      end
    end
  end
end
