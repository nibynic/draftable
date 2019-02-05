class DraftizePosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :draft_author, index: true, polymorphic: true
    add_reference :posts, :draft_master, index: true
  end
end
