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

    def to_draft(author, options = {})
      options[:except] ||= []
      master_drafts.where(draft_author: author).first || begin
        allowed_methods = self.class.draftable_methods - options[:except].map(&:to_s)
        draft = self.class.new(
          attributes.slice(*allowed_methods).merge(
            draft_master: self,
            draft_author: author
          )
        )
        self.class.reflect_on_all_associations.each do |reflection|
          if allowed_methods.include?(reflection.name.to_s)
            opts = options.merge(
              except: options[:except] + [reflection.inverse_of.try { |r| r.name.to_s }].compact
            )
            if reflection.collection?
              allow_copy = reflection.macro == :has_and_belongs_to_many
              draft.send "#{reflection.name}=", (send(reflection.name).map do |record|
                related_record_to_draft(record, author, allow_copy, opts)
              end).compact
            else
              record = send(reflection.name)
              allow_copy = reflection.macro == :belongs_to
              draft.send "#{reflection.name}=", related_record_to_draft(record, author, allow_copy, opts)
            end
          end
        end

        draft.save(validate: false)
        draft
      end
    end

    private

    def related_record_to_draft(record, author, allow_copy, options = {})
      if record.respond_to?(:to_draft)
        record.to_draft(author, options)
      elsif allow_copy
        record
      end
    end
  end
end
