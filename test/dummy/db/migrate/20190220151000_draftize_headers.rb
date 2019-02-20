class DraftizeHeaders < ActiveRecord::Migration[5.2]
  def change
    add_reference :headers, :draft_author, index: true, polymorphic: true
    add_reference :headers, :draft_master, index: true
  end
end
