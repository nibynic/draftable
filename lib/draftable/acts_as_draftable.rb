require_relative "data_synchronizer"
require_relative "rule_parser"

module Draftable
  module ActsAsDraftable
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_draftable(options = nil)
        include ModelExtension
        @draftable_options = options
      end
    end

    module ModelExtension
      extend ActiveSupport::Concern

      included do
        def self.draftable_rules
          @draftable_rules ||= RuleParser.new(self, @draftable_options).parse
        end

        belongs_to :draft_author, optional: true, polymorphic: true
        belongs_to :draft_master, optional: true, class_name: self.name, inverse_of: :drafts
        has_many :drafts, class_name: self.name, foreign_key: :draft_master_id, inverse_of: :draft_master, dependent: :nullify

        scope :draft, -> { where.not(draft_author_id: nil) }
        scope :master, -> { where(draft_author_id: nil) }
      end

      def master?
        draft_author.nil?
      end

      def draft?
        draft_author.present?
      end

      def to_draft(author)
        drafts.find_by(draft_author: author) || begin
          draft = drafts.build(draft_author: author)
          DataSynchronizer.new(self, draft).synchronize
          draft
        end
      end

      def sync_draftable(&block)
        if master?
          synchronizers = drafts.map do |draft|
            DataSynchronizer.new(self, draft)
          end
        else
          synchronizers = [
            DataSynchronizer.new(self, draft_master)
          ] + ((draft_master.try(:drafts) || []) - [self]).map do |draft|
            DataSynchronizer.new(draft_master, draft)
          end
        end
        result = block.call
        synchronizers.map(&:synchronize) if result
        result
      end
    end
  end
end
