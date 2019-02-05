require "rails/generators/active_record/migration/migration_generator"

module Draftable
  class InitGenerator < ActiveRecord::Generators::MigrationGenerator
    source_root File.expand_path('templates', __dir__)

    def create_migration_file
      super
      inject_into_class "app/models/#{name.underscore}.rb", model, "  acts_as_draftable\n"
    end

    private

    def file_name
      "draftize_#{table_name}"
    end

    def model
      @model ||= begin
        klass_name = name.underscore.classify
        klass = klass_name.safe_constantize
        raise "ERROR: model #{klass_name} not found" if klass.nil? || !klass.respond_to?(:table_name)
        klass
      end
    end

    def table_name
      model.table_name
    end

    def set_local_assigns!
      @migration_template = "migration.rb"
      @table_name = table_name
    end
  end
end
