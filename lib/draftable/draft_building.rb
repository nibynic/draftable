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

    def master_drafts
      (draft_master || self).drafts
    end

    def to_draft(author)
      draft, save_queue = build_draft_tree(author)
      save_queue.map &:save
      draft
    end

    private

    def build_draft_tree(author, cache = {})
      existing_draft = master_drafts.where(draft_author: author).first
      if existing_draft.present?
        [existing_draft, []]
      else
        draft = self.class.new
        cache[self] = draft
        save_queue = [draft]

        new_data = attributes.slice(*self.class.draftable_methods).merge(
          draft_master: self,
          draft_author: author
        )
        self.class.reflect_on_all_associations.each do |reflection|
          if self.class.draftable_methods.include?(reflection.name.to_s)
            if reflection.collection?
              allow_copy = reflection.macro == :has_and_belongs_to_many
              prepend = false
              draft_records = []
              nested_queue = []
              send(reflection.name).each do |record|
                draft_record, queue = related_record_to_draft(record, author, allow_copy, cache)
                draft_records << draft_record if draft_record.present?
                nested_queue += queue
              end
              new_data[reflection.name] = draft_records
            else
              allow_copy = prepend = reflection.macro == :belongs_to
              record = send(reflection.name)
              draft_record, nested_queue = related_record_to_draft(record, author, allow_copy, cache)
              new_data[reflection.name] = draft_record
            end
            if prepend
              save_queue = nested_queue + save_queue
            else
              save_queue += nested_queue
            end
          end
        end
        draft.assign_attributes(new_data)
        [draft, save_queue]
      end
    end

    def related_record_to_draft(record, author, allow_copy, cache)
      if record.respond_to?(:to_draft)
        if cache[record].present?
          [cache[record], []]
        else
          record.send(:build_draft_tree, author, cache)
        end
      elsif allow_copy
        [record, []]
      else
        [nil, []]
      end
    end
  end
end
