require_relative "data_synchronizer/snapshots"

module Draftable
  class DataSynchronizer
    include Snapshots

    attr_reader :source, :destination, :previous_state, :current_state, :key_map, :cache

    def initialize(source, destination)
      @source = source
      @destination = destination


      @previous_state = full_snapshot(source)

      mode = destination.persisted? ? (source.master? ? :down : :up) : :full
      destination_state = full_snapshot(destination, mode)
      forced_keys = destination.class.draftable_rules[mode][:force]
      @key_map = destination_state.each.map do |draft, snapshot|
        previous_snapshot = previous_state[draft.draft_master]
        allowed_keys = snapshot.each.select do |key, draft_value|
          previous_value = previous_snapshot[key] if previous_snapshot.present?
          forced_keys.include?(key) || draft_value == previous_value
        end.map &:first
        [draft, allowed_keys]
      end.to_h

      @cache = destination_state.map { |r, data| [r.draft_master, r] }.to_h
    end

    def synchronize
      begin
        source.reload
        @current_state = full_snapshot(source)
      rescue ActiveRecord::RecordNotFound
        @current_state = {}
      end

      draft_root = destination
      author = draft_root.draft_author
      save_queue = []

      # create & update
      traverse(draft_root) do |draft|

        master = draft.draft_master
        if master.present? && current_state[master].present?

          current_snapshot = current_state[master]
          allowed_keys = key_map[draft] || current_snapshot.keys

          new_data = {}
          current_snapshot.slice(*allowed_keys).each do |key, current_value|
            reflection = draft.class.reflect_on_association(key)
            if reflection.present?
              if reflection.collection?
                allow_copy = reflection.macro == :has_and_belongs_to_many
                new_data[key] = current_value.map do |v|
                  materialize_draft(v, author, allow_copy, draft.send(key).method(:build), cache)
                end.compact
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

        allowed_keys

      end

      save_queue.map &:save

      # destroy
      (previous_state.keys - current_state.keys).map do |master|
        draft = cache[master]
        drafted_keys = previous_state[master].keys - (key_map[draft] || [])
        if draft.present? && drafted_keys.empty?
          draft.destroy
        end
      end

    end

    private

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
