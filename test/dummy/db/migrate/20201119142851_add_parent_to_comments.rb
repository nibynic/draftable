class AddParentToComments < ActiveRecord::Migration[5.2]
  def change
    add_reference :comments, :parent, polymorphic: true
  end
end
