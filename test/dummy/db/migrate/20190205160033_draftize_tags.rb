class DraftizeTags < ActiveRecord::Migration[5.2]
  def change
    add_reference :tags, :draft_author, index: true, polymorphic: true
    add_reference :tags, :draft_master, index: true
  end
end
