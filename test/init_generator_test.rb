require 'test_helper'
require 'generators/draftable/init_generator'

class Draftable::InitGeneratorTest < ::Rails::Generators::TestCase

  tests Draftable::InitGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  setup do
    FileUtils.mkdir(File.expand_path("app", destination_root))
    FileUtils.mkdir(File.expand_path("app/models", destination_root))
    File.write(File.expand_path("app/models/sample_model.rb", destination_root), "
      class SampleModel < ApplicationRecord
      end
    ")
  end

  test "it generates migration for given model" do

    run_generator ["sample-model"]

    assert_migration "db/migrate/draftize_my_sample_models.rb" do |content|
      assert_match("add_reference :my_sample_models, :draft_author, index: true, polymorphic: true", content)
      assert_match("add_reference :my_sample_models, :draft_master, index: true", content)
    end

    assert_file "app/models/sample_model.rb", /acts_as_draftable/
  end
end
