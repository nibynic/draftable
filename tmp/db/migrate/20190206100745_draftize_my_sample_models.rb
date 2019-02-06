class DraftizeMySampleModels < ActiveRecord::Migration[5.2]
  def change
    add_reference :my_sample_models, :draft_author, index: true, polymorphic: true
    add_reference :my_sample_models, :draft_master, index: true
  end
end
