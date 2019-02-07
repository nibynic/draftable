module Draftable
  module DataSyncing
    extend ActiveSupport::Concern

    def with_drafts(&block)
      previous_state = draftable_tree_snapshot
      draft_key_maps = drafts.map do |draft|
        snapshot = draft.send(:draftable_tree_snapshot)
        [
          snapshot.each.map do |draft, snapshot|
            previous_snapshot = previous_state[draft.draft_master]
            allowed_keys = snapshot.each.select do |key, draft_value|
              previous_value = previous_snapshot[key] if previous_snapshot.present?
              draft_value == previous_value
            end.map &:first
            [draft, allowed_keys]
          end.to_h,
          snapshot.map { |r, data| [r.draft_master, r] }.to_h
        ]
      end

      result = block.call

      if result
        begin
          reload
          current_state = draftable_tree_snapshot
        rescue ActiveRecord::RecordNotFound
          current_state = {}
        end
        sync_drafts(draft_key_maps, previous_state, current_state)
      end

      result
    end

    private

    def draftable_snapshot
      snapshot = {}.merge(
        self.attributes.slice(*self.class.draftable_methods)
      )
      self.class.reflect_on_all_associations.each do |reflection|
        if self.class.draftable_methods.include?(reflection.name.to_s)
          if reflection.collection?
            snapshot[reflection.name.to_s] = send(reflection.name).map do |record|
              record.try(:draft_master) || record
            end
          else
            record = send(reflection.name)
            snapshot[reflection.name.to_s] = record.try(:draft_master) || record
          end
        end
      end
      snapshot
    end

    def draftable_tree_snapshot
      dict = {}
      traverse_draftable_tree do |record|
        dict[record] = record.send(:draftable_snapshot)
      end
      dict
    end

    def draft_for(author)
      drafts.find_by(draft_author: author)
    end

    def _build_draft(author)
      drafts.find_by(draft_author: author) || self.class.new(draft_master: self, draft_author: author)
    end

    def sync_drafts(draft_key_maps, previous_state, current_state)
      draft_key_maps.each do |draft_key_map, cache|

        draft_root = draft_key_map.keys.first
        author = draft_root.draft_author
        save_queue = []

        # create & update
        draft_root.send(:traverse_draftable_tree) do |draft|

          master = draft.draft_master
          if master.present? && current_state[master].present?

            current_snapshot = current_state[master]
            allowed_keys = draft_key_map[draft] || current_snapshot.keys

            new_data = {}
            current_snapshot.slice(*allowed_keys).each do |key, current_value|
              reflection = draft.class.reflect_on_association(key)
              if reflection.present?
                if reflection.collection?
                  allow_copy = reflection.macro == :has_and_belongs_to_many
                  new_data[key] = current_value.map do |v|
                    materialize_draft(v, author, allow_copy, draft.send(key).method(:build), cache)
                  end
                else
                  allow_copy = reflection.macro == :belongs_to
                  if current_value.present?
                    new_data[key] = materialize_draft(current_value, author, allow_copy, draft.method("build_#{key}"), cache)
                  else
                    new_data[key] = nil
                  end
                end
              else
                new_data[key] = current_value
              end
            end
            draft.assign_attributes(new_data)
            save_queue << draft

          end

        end

        save_queue.map &:save

        # destroy
        (previous_state.keys - current_state.keys).map do |master|
          draft = cache[master]
          drafted_keys = previous_state[master].keys - (draft_key_map[draft] || [])
          if draft.present? && drafted_keys.empty?
            draft.destroy
          end
        end

      end
    end

    def materialize_draft(master, author, allow_copy, builder, cache)
      if master.respond_to?(:to_draft)
        cache[master] ||=
          master.drafts.find_by(draft_author: author) ||
          builder.call(draft_master: master, draft_author: author)
      elsif allow_copy
        master
      end
    end

  end
end
