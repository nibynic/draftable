require_relative "data_synchronizer/snapshots"

module Draftable
  class DataSynchronizer
    include Snapshots

    attr_reader :source, :destination, :previous_state, :current_state, :key_map,
      :rules_map, :author

    def initialize(source, destination_or_params, rules_map = {})
      @source = source
      if destination_or_params.is_a?(ActiveRecord::Base)
        @destination = destination_or_params
      else
        @destination = source.class.new(destination_or_params || {})
        if source.master?
          @destination.draft_master = source
        else
          @destination.drafts = [source]
        end
      end
      @rules_map = rules_map
      @author = source.draft? ? source.draft_author : destination.draft_author

      @previous_state = full_snapshot(source)

      mode = destination.persisted? ? (source.master? ? :down : :up) : :full
      destination_state = full_snapshot(destination, mode)
      forced_keys = rules_for(destination.class)[mode][:force]
      @key_map = destination_state.each.map do |destination_record, snapshot|
        previous_snapshot = previous_state[reflect(destination_record)]
        allowed_keys = snapshot.each.select do |key, destination_value|
          previous_value = previous_snapshot[key] if previous_snapshot.present?
          forced_keys.include?(key) || destination_value == previous_value
        end.map &:first
        [destination_record, allowed_keys]
      end.to_h

      destination_state.map do |destination_record, data|
        cache(reflect(destination_record)) { destination_record }
      end
    end

    def synchronize
      begin
        source.reload
        @current_state = full_snapshot(source)
      rescue ActiveRecord::RecordNotFound
        @current_state = {}
      end

      save_queue = []

      # create & update
      traverse(destination) do |destination_record|

        source_record = reflect(destination_record)
        if source_record.present? && current_state[source_record].present?

          current_snapshot = current_state[source_record]
          allowed_keys = key_map[destination_record] || current_snapshot.keys

          new_data = {}
          current_snapshot.slice(*allowed_keys).each do |key, current_value|
            reflection = destination_record.class.reflect_on_association(key)
            if reflection.present?
              if reflection.collection?
                allow_copy = reflection.macro == :has_and_belongs_to_many
                new_data[key] = current_value.map do |v|
                  materialize_as_destination(v, allow_copy, destination_record.send(key).method(:build))
                end.compact
              else
                allow_copy = reflection.macro == :belongs_to
                if current_value.present?
                  new_data[key] = materialize_as_destination(current_value, allow_copy, destination_record.method("build_#{key}"))
                else
                  new_data[key] = nil
                end
              end
            else
              new_data[key] = current_value
            end
          end
          destination_record.assign_attributes(new_data)

          save_queue << destination_record

        end

        allowed_keys

      end

      save_queue.map &:save

      # destroy
      (previous_state.keys - current_state.keys).map do |source_record|
        destination_record = cache(source_record)
        destination_changed_keys = previous_state[source_record].keys - (key_map[destination_record] || [])
        if destination_record.present? && destination_changed_keys.empty?
          destination_record.destroy
        end
      end

    end

    private

    def reflect(record)
      record.draft? ?
        record.draft_master :
        (
          record.drafts.find_by(draft_author: author) ||
          record.drafts.find { |r| r.draft_author == author }
        )
    end

    def materialize_as_destination(source_record, allow_copy, builder)
      if source_record.respond_to?(:to_draft)
        if source_record.master? == destination.master?
          source_record
        else

          cache(source_record) do
            reflect(source_record) ||
            (source_record.draft? ?
              builder.call(drafts: [source_record]) :
              builder.call(draft_master: source_record, draft_author: author))
          end
        end
      elsif allow_copy
        source_record
      end
    end

    def rules_for(klass)
      rules_map[klass] || klass.draftable_rules
    end

    def cache(record)
      @cache ||= []
      @cache.find { |key, value| key == record }.try(:last) || begin
        if block_given?
          value = yield
          @cache << [record, value]
          value
        end
      end
    end

  end
end
