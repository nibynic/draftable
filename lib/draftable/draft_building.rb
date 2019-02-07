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
      cache = {}
      queue = []
      traverse_draftable_tree do |master|
        queue << master.send(:build_draft, author, cache)
      end
      queue.map &:save
      drafts.find_by(draft_author: author)
    end

    private

    def traverse_draftable_tree(visited = [], &block)
      visited << self
      yield self
      self.class.reflect_on_all_associations.each do |reflection|
        if self.class.draftable_methods.include?(reflection.name.to_s)
          if reflection.collection?
            records = send(reflection.name)
          else
            reflection.macro == :belongs_to
            records = [send(reflection.name)].compact
          end
          records.map do |record|
            if !visited.include?(record) && record.respond_to?(:to_draft)
              record.send(:traverse_draftable_tree, visited, &block)
            else
              []
            end
          end.reduce([], :+)
        end
      end
    end

    def build_draft(author, cache = {})
      draft = drafts.where(draft_author: author).first ||
        self.class.new(draft_master: self, draft_author: author)
      cache[self] = draft

      new_data = attributes.slice(*self.class.draftable_methods)
      self.class.reflect_on_all_associations.each do |reflection|
        if self.class.draftable_methods.include?(reflection.name.to_s)
          if reflection.collection?
            allow_copy = reflection.macro == :has_and_belongs_to_many
            draft_records = send(reflection.name).map do |record|
              related_record_to_draft(record, author, allow_copy, cache)
            end.compact
            new_data[reflection.name] = draft_records
          else
            allow_copy = reflection.macro == :belongs_to
            record = send(reflection.name)
            new_data[reflection.name] = related_record_to_draft(record, author, allow_copy, cache)
          end
        end
      end
      draft.assign_attributes(new_data)

      draft
    end

    def related_record_to_draft(record, author, allow_copy, cache)
      if record.respond_to?(:to_draft)
        cache[record] || record.send(:build_draft, author, cache)
      elsif allow_copy
        record
      end
    end
  end
end
