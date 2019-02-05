class DraftizeComments < ActiveRecord::Migration[5.2]
  def change
    add_reference :comments, :draft_author, index: true, polymorphic: true
    add_reference :comments, :draft_master, index: true
  end
end
