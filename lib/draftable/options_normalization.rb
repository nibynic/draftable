module Draftable
  module OptionsNormalization
    extend ActiveSupport::Concern

    class_methods do
      def draftable_methods
        @draftable_methods ||= begin
          except = @draftable_options[:except] || []
          except = [except] unless except.is_a? Array
          only = @draftable_options[:only] || []
          only = [only] unless only.is_a? Array

          blacklist = (
            ["id", "created_at", "updated_at", "draft_author", "draft_master", "drafts"] +
            self.reflect_on_all_associations.select(&:belongs_to?).collect { |r| r.foreign_key.to_s } +
            self.reflect_on_all_associations.select(&:belongs_to?).collect { |r| r.foreign_type.to_s }
          ).compact + except.map(&:to_s)

          relationship_names = self.reflect_on_all_associations.collect { |r| r.name.to_s }
          base = self.attribute_names + relationship_names - blacklist

          only.any? ? only.map(&:to_s).select { |i| base.include?(i) } : base
        end
      end
    end
  end
end
