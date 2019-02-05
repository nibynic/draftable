class <%= class_name.underscore.camelize %> < ActiveRecord::Migration[5.2]
  def change
    add_reference :<%= table_name %>, :draft_author, index: true, polymorphic: true
    add_reference :<%= table_name %>, :draft_master, index: true
  end
end
