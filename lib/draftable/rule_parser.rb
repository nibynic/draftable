module Draftable
  class RuleParser
    attr_reader :rules, :klass

    def initialize(klass, rules = nil)
      @rules = rules || [{
        up: :none,
        down: { create: :force, update: :merge, destroy: :merge },
        except: []
      }]
      @klass = klass
    end

    def parse
      key_map = {
        up:   {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        },
        down: {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        }
      }

      keys_left = all_keys
      rules.each do |rule|
        if rule[:only].present?
          keys = normalize_array(rule[:only]) & keys_left
        else
          keys = keys_left - normalize_array(rule[:except])
        end
        [:up, :down].each do |direction|
          normalize_strategy(rule[direction]).each do |action, strategy|
            if [:force, :merge].include?(strategy)
              key_map[direction][action][strategy] += keys
            end
          end
        end
        keys_left -= keys
      end

      key_map
    end

    private

    def all_keys
      @all_keys ||= begin
        blacklist = (
          ["id", "created_at", "updated_at", "draft_author", "draft_master", "drafts"] +
          klass.reflect_on_all_associations.select(&:belongs_to?).collect { |r| r.foreign_key.to_s } +
          klass.reflect_on_all_associations.select(&:belongs_to?).collect { |r| r.foreign_type.to_s }
        ).compact

        relationship_names = klass.reflect_on_all_associations.collect { |r| r.name.to_s }

        (klass.attribute_names + relationship_names - blacklist).sort
      end
    end

    def normalize_array(value = [])
      value = [value] unless value.is_a? Array
      value.map! &:to_s
      value
    end

    def normalize_strategy(hash_or_symbol)
      if hash_or_symbol.is_a? Hash
        {
          create: :none,
          update: :none,
          destroy: :none
        }.merge(hash_or_symbol)
      else
        {
          create: hash_or_symbol,
          update: hash_or_symbol,
          destroy: hash_or_symbol
        }
      end
    end
  end
end
