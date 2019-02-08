module Draftable
  module DraftBuilding
    extend ActiveSupport::Concern

    included do
      belongs_to :draft_author, optional: true, polymorphic: true
      belongs_to :draft_master, optional: true, class_name: self.name
      has_many :drafts, class_name: self.name, foreign_key: :draft_master_id, dependent: :nullify

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
        DataSynchronizer.new(self, draft, true).synchronize
        draft
      end
    end
  end
end
