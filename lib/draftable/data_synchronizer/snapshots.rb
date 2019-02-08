module Draftable
  module Snapshots

    def snapshot(record, keys = [])
      keys = keys.map &:to_s
      data = {}.merge(
        record.attributes.slice(*keys)
      )
      record.class.reflect_on_all_associations.each do |reflection|
        if keys.include?(reflection.name.to_s)
          if reflection.collection?
            data[reflection.name.to_s] = record.send(reflection.name).map do |related|
              related.try(:draft_master) || related
            end
          else
            related = record.send(reflection.name)
            data[reflection.name.to_s] = related.try(:draft_master) || related
          end
        end
      end
      data
    end

    def full_snapshot(record)
      dict = {}
      traverse(record) do |related|
        dict[related] = snapshot(related, related.class.draftable_methods)
        related.class.draftable_methods
      end
      dict
    end

    def traverse(record, visited = [], &block)
      visited << record
      keys = (yield(record) || []).map &:to_s
      record.class.reflect_on_all_associations.each do |reflection|
        if keys.include?(reflection.name.to_s)
          if reflection.collection?
            records = record.send(reflection.name)
          else
            records = [record.send(reflection.name)].compact
          end
          records.map do |related|
            if !visited.include?(related) && related.respond_to?(:to_draft)
              traverse(related, visited, &block)
            else
              []
            end
          end.reduce([], :+)
        end
      end
    end
  end
end
